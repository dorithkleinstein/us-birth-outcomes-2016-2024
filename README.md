# US birth outcomes, 2016 to 2024

A dbt project over CDC WONDER natality data, covering every US state across nine years, by mother's race, education and age cohort.

This is the pipeline behind a published analysis. The written piece is [The averages moved. The structure did not.](https://www.linkedin.com/pulse/averages-moved-structure-did-dorith-kleinstein-zjamf) and the interactive report is [US Birth Outcomes 2016-2024](https://datastudio.google.com/reporting/67893ee7-9da4-4c9b-ab32-6f7903caed08), which opens without a Google account.

Everything here is reproducible. The source extracts, the seeds, the models and the tests are all in this repository, so `dbt build` rebuilds the entire warehouse in your own project from the original government files.

## Why this data, and not the convenient copy

I went looking for a subject before I went looking for a dataset. Most practice data is retail revenue or customer churn, and this topic looked like it might hold something worth knowing rather than something worth demonstrating.

There is a ready-made copy of US natality data sitting in BigQuery as a public dataset. It is genuinely useful for learning technique, and it runs from 1969 to 2008. Everything I wanted to ask about was in the last decade, which is not in it. There was also a field in that copy that I could not get a straight explanation of, and chasing that is what took me to the source.

The source is CDC WONDER, and I pulled from it myself. Three days of work, and the reason this repository opens with 55 export files instead of a table name.

## What the analysis found

Average birth weight fell about 25 grams nationally over the nine years, and average gestation shortened. The national averages moved.

The structure underneath them did not. The gap between the states with the best and worst outcomes is the same size at the end of the period as at the start. The gap between racial groups within a state is the same size. Education tracks birth weight in the same direction, with the same spacing, in 2024 as in 2016. A national trend moved every group at once without rearranging any of them.

A later piece, [Babies are not smaller. They are arriving earlier.](https://www.linkedin.com/feed/update/urn:li:activity:7505263487837896706/), takes the weight decline apart. At every gestational age from 36 to 41 weeks a baby weighs almost exactly what it did in 2016. What changed is when babies arrive: 37-week births rose from 8.8% to 12.4% of singletons, every year, without a single reversal. The weight decline is a timing effect.

## A correction, 10 September 2026

An earlier version of `state_health_ranking` produced a composite "Health Index" from birth weight and gestational age, and ranked states on it. The composite measured each state's absolute distance from a reference value, which meant a state was penalised for rising above the reference exactly as much as for falling below it. Alaska has the highest average birth weight in the country in all nine years, and the index ranked it between 33rd and 47th.

The measure was wrong in shape rather than in scale, so reweighting could not fix it. It was removed. States are now ranked on average birth weight alone, and every chart that used the composite was rebuilt. The model in this repository is the corrected one.

## On the use of AI

I used AI throughout this project, and I would rather say so plainly than have a reader work it out.

The questions are mine, starting with the one this whole project rests on: the convenient copy was already in BigQuery and I chose not to use it. Which cut of the data to pull and at what grain, why the study starts in 2016 and not 2007, why an average across states has to be weighted by births, what the result means and what it does not. So are the 55 queries against CDC WONDER, run one state at a time because there was no faster way through.

The models and these READMEs were written with Claude. I read everything that goes out under my name, and where the wording is mine it is because I rewrote it. Sometimes my version was better. Sometimes it was not worth an hour of my time to find out.

The broken health index is the part worth knowing about. It was found because a reader asked a question about the published piece, I did not have a good answer, and checking it properly turned up a measure that was wrong in shape rather than in scale. The question came from a person. The check was done with the tool. Neither half would have got there alone, and that is roughly how I work.

## How the data got here

| Stage | What happens | Where |
|---|---|---|
| 1. Pull | 55 queries against CDC WONDER, exported as tab-delimited files | `pull/` |
| 2. Seed | Extracts consolidated into CSVs that dbt loads | `seeds/` |
| 3. Stage | Typed, cleaned, labelled, one row per grain | `models/staging/` |
| 4. Mart | Facts with clinical flags and reliability flags | `models/marts/` |
| 5. Present | Looker Studio, linked above | outside this repo |

`pull/` has its own README explaining why there are 55 files rather than 2, and what the footers in them are good for.

## Why the study starts in 2016

Two reasons, both in the caveats printed at the bottom of every extract in `pull/`.

**Single race categories do not exist before 2016.** Maternal race for earlier years is recoded to "Not Available", so a race dimension going back further would be empty.

**Education and prenatal care data are coded "Excluded" for many states in earlier years**, because those states were still using the 1989 birth certificate and the values are not comparable to the 2003 revision. Connecticut through 2015, New Jersey through 2015, Rhode Island through 2014, and about thirty others through various years. Including them would have produced a real-looking trend made entirely of reporting changes.

## Decisions worth knowing about

**Averages are births-weighted, never plain.** `sum(avg_birth_weight_grams * births) / sum(births)`. A plain average across race groups within a state, or across states within a region, counts Wyoming the same as California. The weighting is written into the SQL with the reason above it.

**Suppressed cells are kept, not dropped and not zero-filled.** CDC suppresses any cell with fewer than 10 births. Those rows stay in the fact tables with `births` set to NULL and `is_suppressed` set to TRUE, so a reader can see where the data is absent instead of inferring it from a gap. They are excluded from weighted averages by the `where not is_suppressed` filter, not by being deleted.

WONDER withholds the count on those cells but still returns the averages, and where a cell holds a single birth the average is that birth's own value. Those derived measures are emptied here and in `pull/`, which changes no published figure because nothing ever read them. `pull/README.md` records exactly what was emptied and why.

**Thin cells are flagged separately from suppressed ones.** `is_reliable` is TRUE at 25 births or more. The five-way table, state by race by education by age by year, produces many cells that clear CDC's suppression threshold and are still too small to average meaningfully. Suppression is CDC's judgement; reliability is mine, and they are different columns for that reason.

**Group averages are labelled as group averages.** `is_low_birth_weight_avg` is TRUE when a group's *average* is below 2,500g. It does not mean the babies in that group were individually low birth weight, and the column description says so, because that is exactly the error a reader makes at a glance.

## Layout

```
models/staging/     5 models, materialized as views
models/marts/       6 models, materialized as tables
models/*/schema.yml column descriptions and tests
seeds/              6 CSVs loaded by dbt seed
pull/               the 55 CDC WONDER extracts, unmodified
```

Tests are `not_null` and `accepted_values` on the dimensions. One `accepted_values` test is deliberately omitted and the omission is commented where it happens: dbt generates broken SQL for values containing apostrophes, which the education labels do, so the model filters invalid categories instead.

## Running it

You need dbt and a BigQuery project of your own.

```bash
pip install dbt-bigquery
# add a 'birth_outcomes' profile to ~/.dbt/profiles.yml pointing at your project
dbt seed
dbt run
dbt test
```

No credentials are in this repository. The connection lives in your own `~/.dbt/profiles.yml`.

The seeds are already in `seeds/`, so step 1 is optional. `pull/` is there if you want to rebuild the seeds from the original extracts, or to check that the seeds match what CDC actually returned.

## Source and citation

Centers for Disease Control and Prevention, National Center for Health Statistics. National Vital Statistics System, Natality on CDC WONDER Online Database. Data are from the Natality Records 2007-2024, as compiled from data provided by the 57 vital statistics jurisdictions through the Vital Statistics Cooperative Program. Accessed at http://wonder.cdc.gov/natality-current.html.

Extracts were pulled in May 2026. Query dates are printed in each file.

## Author

Dorith Kleinstein, [linkedin.com/in/dorithkleinstein](https://www.linkedin.com/in/dorithkleinstein), dorithkleinstein@gmail.com
