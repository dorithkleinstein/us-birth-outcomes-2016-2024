# Party switch: replacing an indirect argument with a measurement

A difference-in-differences check on one claim from the analysis in this repository: whether a change in a US state governor's party is followed by a change in average birth weight.

## The question

The party-switch check, built by `models/marts/fct_party_switch_effect.sql`, compares average birth weight in the last year under the old party to the first year under the new one, for each state where the governor changed party. The argument originally made from it was that birth weight declined regardless of which direction the switch went.

That is a reasonable argument and it is indirect. It infers the absence of an effect from a pattern rather than measuring the effect and finding it small. The notebook here does the measurement.

## The method

Difference-in-differences. Each switching state's before-and-after change is compared against the change over the same window in states that did not switch, so the national decline that was happening anyway is netted out instead of being charged to the governor.

A valid control for a given event is a state whose governor's party was unchanged at both ends of that specific window. That definition excludes any other state that switched during the same period without needing a special case for it.

State-year averages are births-weighted, `SUM(avg_birth_weight_grams * births) / SUM(births)`, not a simple mean, so a small state does not count the same as a large one.

## What I found

Across 22 switch events:

| Estimate | Value |
|---|---|
| Naive before-and-after | −6.6 g |
| Difference-in-differences | −2.392 g (SD 5.339, range −15.105 to +6.042) |
| Paired t-test | t = −2.101, p = 0.0479 |
| Wilcoxon signed-rank | W = 70.0, p = 0.0684 |

**Most of the apparent effect was the national trend.** The naive estimate is nearly three times the trend-adjusted one. That is the whole value of the method: it separates "this state changed" from "this state changed more than everywhere else did anyway."

**The residual is not cleanly zero either.** The two tests land on opposite sides of the conventional 0.05 line, the t-test just under and the Wilcoxon, which is less sensitive to any single extreme event, just over. A result that flips depending on which reasonable test you pick is not evidence in either direction. It is evidence of a small and genuinely uncertain effect.

**Revised finding, replacing the original argument.** The direction-invariance argument was directionally right, but "no effect" overstated it. A small, borderline residual decline of about 2 grams remains after controlling for the shared trend: too small to act on with confidence, too present to declare absent.

## Context added since

The national decline this notebook nets out, 3,267 g to 3,242 g over the study period, has since been explained. It is not that babies are smaller. Average gestation shortened, and at every gestational age from 36 to 41 weeks a baby weighs almost exactly what it did in 2016. That makes the control trend here a timing effect rather than a growth effect, which does not change the difference-in-differences result but does change what the thing being controlled for actually is.

## What this leaves open

Twenty-two events is a small number for a design this sensitive to the choice of window. A single year before and a single year after is also a blunt instrument: the mechanism by which a governor's party could affect birth weight, if there is one, would act through policy that takes longer than twelve months to reach a delivery room. An event-study specification with several years either side is the obvious next version, and the data supports it.

## Running it

Requires `pandas`, `numpy`, `scipy`, and the marts built by `dbt run` from this repository. The notebook reads them from BigQuery through the `bq` command-line tool; point it at your own project name.
