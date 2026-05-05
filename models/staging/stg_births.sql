with source as (

    select * from {{ ref('births_by_state_race_year') }}

),

cleaned as (

    select
        region,
        state,
        state_code,
        mother_race,
        cast(year as integer)                       as year,

        -- births is null when CDC suppressed the value (small population cell)
        cast(births as integer)                     as births,

        cast(avg_birth_weight_grams as float64)     as avg_birth_weight_grams,
        cast(sd_birth_weight_grams as float64)      as sd_birth_weight_grams,

        cast(avg_mother_age as float64)             as avg_mother_age,
        cast(sd_mother_age as float64)              as sd_mother_age,

        cast(avg_gestational_age_weeks as float64)  as avg_gestational_age_weeks,
        cast(sd_gestational_age_weeks as float64)   as sd_gestational_age_weeks

    from source

    -- exclude placeholder race categories
    where mother_race not in (
        'Unknown or Not Stated',
        'Not Available',
        'Not Reported'
    )
    -- exclude pre-2016 rows where Single Race data is unavailable
    and cast(year as integer) >= 2016

)

select * from cleaned
