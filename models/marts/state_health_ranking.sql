/*
  State-level birth health ranking by year.

  Methodology:
  - Aggregates fct_birth_outcomes to state × year level using births-weighted averages
    so larger racial groups contribute proportionally to the state score.
  - Suppressed cells (births IS NULL) are excluded from the weighted average.
  - Scores each state on distance from clinically optimal values:
      Birth weight optimal: 3,250g  (midpoint of normal range 2,500–4,000g, WHO/CDC)
      Gestational age optimal: 39 weeks  (midpoint of full-term range 37–41 weeks)
  - Normalizes each distance by half the normal range so both measures
    contribute equally to the composite score regardless of units:
      Birth weight normalization divisor: 750g  (= 1,500g range / 2)
      Gestational age normalization divisor: 2 weeks  (= 4-week range / 2)
  - Lower composite score = closer to optimal = healthier ranking.
*/

with base as (

    select * from {{ ref('fct_birth_outcomes') }}
    where not is_suppressed

),

-- weighted average per state × year across all race groups
state_year as (

    select
        region,
        state,
        state_code,
        year,

        sum(births)                                                     as total_births,

        -- births-weighted average birth weight
        sum(avg_birth_weight_grams * births) / nullif(sum(births), 0)   as wtd_avg_birth_weight_grams,

        -- births-weighted average gestational age
        sum(avg_gestational_age_weeks * births) / nullif(sum(births), 0) as wtd_avg_gestational_age_weeks,

        -- births-weighted average mother age (contextual, not scored)
        sum(avg_mother_age * births) / nullif(sum(births), 0)           as wtd_avg_mother_age

    from base
    group by region, state, state_code, year

),

scored as (

    select
        *,

        -- distance from optimal (lower = healthier)
        abs(wtd_avg_birth_weight_grams - 3250)      as birth_weight_distance,
        abs(wtd_avg_gestational_age_weeks - 39)     as gestational_age_distance,

        -- normalized scores (divides by half the clinical normal range)
        abs(wtd_avg_birth_weight_grams - 3250) / 750.0      as birth_weight_score,
        abs(wtd_avg_gestational_age_weeks - 39) / 2.0       as gestational_age_score,

        -- composite score: sum of normalized distances (lower = healthier)
        (abs(wtd_avg_birth_weight_grams - 3250) / 750.0)
        + (abs(wtd_avg_gestational_age_weeks - 39) / 2.0)   as composite_health_score

    from state_year

),

ranked as (

    select
        *,
        rank() over (
            partition by year
            order by composite_health_score asc
        )                                                               as health_rank

    from scored

)

select * from ranked
