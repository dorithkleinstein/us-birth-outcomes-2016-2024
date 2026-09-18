-- models/marts/fct_party_switch_effect.sql
-- For each state that changed governor party, compares birth weight
-- in the last year under the old party vs the first year under the new party.
-- One row per switch event per state.
-- switch_number = 1 is the first switch; use this for the main Tableau chart.
-- Nevada has switch_number = 2 (D->R, 2022->2023) — handle as a callout.

with state_year_bw as (

    -- Aggregate birth outcomes to state x year level (across all race/education/age)
    select
        state,
        year,
        governor_party,
        safe_divide(
            sum(avg_birth_weight_grams * births),
            sum(births)
        )                               as wtd_avg_birth_weight,
        sum(births)                     as total_births

    from {{ ref('fct_birth_outcomes_with_party') }}
    where is_reliable = true
      and governor_party is not null
    group by state, year, governor_party

),

with_previous as (

    select
        state,
        year,
        governor_party,
        wtd_avg_birth_weight,
        total_births,
        lag(governor_party)        over (partition by state order by year) as prev_governor_party,
        lag(wtd_avg_birth_weight)  over (partition by state order by year) as prev_wtd_avg_birth_weight,
        lag(year)                  over (partition by state order by year) as prev_year

    from state_year_bw

),

switch_events as (

    select
        state,
        prev_year                                               as before_year,
        year                                                    as after_year,
        prev_governor_party                                     as party_before,
        governor_party                                          as party_after,
        concat(prev_governor_party, ' → ', governor_party)     as switch_direction,
        prev_wtd_avg_birth_weight                               as birth_weight_before,
        wtd_avg_birth_weight                                    as birth_weight_after,
        wtd_avg_birth_weight - prev_wtd_avg_birth_weight        as birth_weight_change,
        row_number() over (partition by state order by year)    as switch_number

    from with_previous
    where governor_party        != prev_governor_party
      and prev_governor_party   is not null

)

select * from switch_events
order by state, switch_number
