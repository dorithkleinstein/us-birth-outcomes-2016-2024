with stg as (

    select * from {{ ref('stg_births_education_age') }}

),

final as (

    select
        -- dimensions
        region,
        state,
        state_code,
        mother_race,
        education,
        education_label,
        education_code,
        age_of_mother,
        age_label,
        age_order,
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

        -- suppression flag: CDC suppressed the birth count (< 10 births in cell)
        case
            when births is null then true
            else false
        end                                         as is_suppressed,

        -- reliability flag: cells with very few births produce noisy averages.
        -- births >= 25 is a standard threshold for statistical reliability.
        -- especially important here: race × education × age × small states
        -- creates many thin cells that pass CDC suppression but are still noisy.
        -- use this flag to dim or exclude unreliable cells in visualizations.
        case
            when births >= 25 then true
            else false
        end                                         as is_reliable

    from stg

)

select * from final
