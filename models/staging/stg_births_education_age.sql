with source as (

    select * from {{ ref('births_by_state_race_education_age_year') }}

),

cleaned as (

    select
        region,
        state,
        state_code,
        mother_race,
        education,

        -- short display label for charts (same mapping as stg_births_education)
        case cast(education_code as integer)
            when 1 then '< 9th Grade'
            when 2 then 'Some High School'
            when 3 then 'HS / GED'
            when 4 then 'Some College'
            when 5 then 'Associate\'s'
            when 6 then 'Bachelor\'s'
            when 7 then 'Master\'s'
            when 8 then 'Doctorate / Prof.'
        end                                         as education_label,

        safe_cast(education_code as integer)        as education_code,

        -- CDC full label for age cohort (e.g. '25-29 years')
        age_of_mother,

        -- short display label for age cohort charts
        case age_of_mother
            when 'Under 15 years'    then '< 15'
            when '15-19 years'       then '15-19'
            when '20-24 years'       then '20-24'
            when '25-29 years'       then '25-29'
            when '30-34 years'       then '30-34'
            when '35-39 years'       then '35-39'
            when '40-44 years'       then '40-44'
            when '45-49 years'       then '45-49'
            when '50 years and over' then '50+'
        end                                         as age_label,

        -- integer sort order for charts (CDC age_of_mother_code is not cleanly
        -- numeric: 'Under 15 years' is coded '15', same as start of next band)
        case age_of_mother
            when 'Under 15 years'    then 1
            when '15-19 years'       then 2
            when '20-24 years'       then 3
            when '25-29 years'       then 4
            when '30-34 years'       then 5
            when '35-39 years'       then 6
            when '40-44 years'       then 7
            when '45-49 years'       then 8
            when '50 years and over' then 9
        end                                         as age_order,

        safe_cast(year as integer)                       as year,

        -- births is null when CDC suppressed the value (small population cell)
        -- safe_cast used throughout: CDC uses 'Not Applicable' for some measures
        -- in very thin cells (e.g. gestational age when birth weight is available).
        -- safe_cast returns null rather than erroring, matching suppression treatment.
        safe_cast(births as integer)                     as births,

        safe_cast(avg_birth_weight_grams as float64)     as avg_birth_weight_grams,
        safe_cast(sd_birth_weight_grams as float64)      as sd_birth_weight_grams,

        safe_cast(avg_mother_age as float64)             as avg_mother_age,
        safe_cast(sd_mother_age as float64)              as sd_mother_age,

        safe_cast(avg_gestational_age_weeks as float64)  as avg_gestational_age_weeks,
        safe_cast(sd_gestational_age_weeks as float64)   as sd_gestational_age_weeks

    from source

    -- exclude placeholder race categories
    where mother_race not in (
        'Unknown or Not Stated',
        'Not Available',
        'Not Reported'
    )
    -- exclude unknown or excluded education categories
    and education not in (
        'Unknown or Not Stated',
        'Not Reported',
        'Excluded',
        'Not Applicable'
    )
    and education is not null
    -- exclude unknown age categories
    and age_of_mother not in (
        'Unknown or Not Stated',
        'Not Reported'
    )
    and age_of_mother is not null

)

select * from cleaned
