/*
  State-level birth outcome averages by year.

  Methodology:
  - Aggregates fct_birth_outcomes to state × year level using births-weighted averages
    so larger racial groups contribute proportionally to the state average.
  - Suppressed cells (births IS NULL) are excluded from the weighted average.
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

)

select * from state_year
