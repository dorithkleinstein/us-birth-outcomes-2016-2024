with source as (

    select * from {{ ref('births_by_state_education_race_year') }}

),

cleaned as (

    select
        region,
        state,
        state_code,
        race                                        as mother_race,
        education,

        -- short display label for charts and dashboards
        -- matches on education_code (integer) to avoid apostrophe quoting issues
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

        cast(education_code as integer)             as education_code,
        cast(year as integer)                       as year,

        -- births is null when CDC suppressed the value (small population cell)
        cast(births as integer)                     as births,

        cast(avg_birth_weight_g as float64)         as avg_birth_weight_grams,
        cast(sd_birth_weight_g as float64)          as sd_birth_weight_grams,

        cast(avg_mother_age as float64)             as avg_mother_age,
        cast(sd_mother_age as float64)              as sd_mother_age,

        cast(avg_gestational_age_wks as float64)    as avg_gestational_age_weeks,
        cast(sd_gestational_age_wks as float64)     as sd_gestational_age_weeks

    from source

    -- safety filter: exclude any placeholder race categories that slipped through
    where race not in (
        'Unknown or Not Stated',
        'Not Available',
        'Not Reported'
    )
    -- safety filter: exclude unknown or excluded education categories
    and education not in (
        'Unknown or Not Stated',
        'Not Reported',
        'Excluded',
        'Not Applicable'
    )
    and education is not null

)

select * from cleaned
