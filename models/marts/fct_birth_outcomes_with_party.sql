-- models/marts/fct_birth_outcomes_with_party.sql
-- Adds governor party and president party to the detailed birth outcomes fact
-- table. One row per state x year x race x education x age group.
-- Join is on state_name + year — confirmed both sides use full state names
-- including "District of Columbia".

with birth_outcomes as (

    select * from {{ ref('fct_birth_outcomes_education_age') }}

),

political_control as (

    select * from {{ ref('stg_political_control') }}

)

select
    -- Birth outcome dimensions
    b.state,
    b.state_code,
    b.year,
    b.mother_race,
    b.education_label,
    b.education_code,
    b.age_of_mother,
    b.age_label,
    b.age_order,

    -- Birth outcome measures
    b.births,
    b.avg_birth_weight_grams,
    b.avg_gestational_age_weeks,

    -- Reliability flags
    b.is_reliable,
    b.is_suppressed,
    b.is_low_birth_weight_avg,
    b.is_preterm_avg,

    -- Political party dimensions
    p.governor_party,
    p.president_party,
    p.president_name,
    p.same_party_as_president

from birth_outcomes b
left join political_control p
    on  b.state = p.state_name
    and b.year  = p.year
