-- models/staging/stg_political_control.sql
-- Combines state-level governor party and national president party into one
-- clean staging layer. One row per state + year (2016-2024).

with state_party as (

    select
        state_name,
        cast(state_fips as string)  as state_fips,
        cast(year as int64)         as year,
        governor_party

    from {{ ref('political_control_by_state_year') }}

),

national_party as (

    select
        cast(year as int64)         as year,
        president_name,
        president_party

    from {{ ref('political_control_national_by_year') }}

)

select
    s.state_name,
    s.state_fips,
    s.year,
    s.governor_party,
    n.president_name,
    n.president_party,
    (s.governor_party = n.president_party) as same_party_as_president

from state_party s
left join national_party n using (year)
