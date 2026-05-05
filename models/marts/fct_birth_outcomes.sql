with stg as (

    select * from {{ ref('stg_births') }}

),

final as (

    select
        -- dimensions
        region,
        state,
        state_code,
        mother_race,
        year,

        -- volume
        births,

        -- birth weight outcomes (grams)
        avg_birth_weight_grams,
        sd_birth_weight_grams,

        -- low birth weight flag (<2500g is the clinical threshold)
        case
            when avg_birth_weight_grams < 2500 then true
            else false
        end                                         as is_low_birth_weight_avg,

        -- mother age
        avg_mother_age,
        sd_mother_age,

        -- gestational age outcomes (weeks)
        avg_gestational_age_weeks,
        sd_gestational_age_weeks,

        -- preterm flag (<37 weeks is the clinical threshold)
        case
            when avg_gestational_age_weeks < 37 then true
            else false
        end                                         as is_preterm_avg,

        -- suppression flag for transparency
        case
            when births is null then true
            else false
        end                                         as is_suppressed

    from stg

)

select * from final
