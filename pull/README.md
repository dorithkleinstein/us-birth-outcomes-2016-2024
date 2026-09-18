# The CDC WONDER extracts

55 files, exactly as CDC WONDER returned them. Nothing has been edited, reordered or cleaned.

They are here so that the pull itself is reproducible, not just the transformation. Most public data projects begin at a CSV that somebody else prepared. This one begins at a government query tool with a data use agreement, a session timeout and a result-size limit, and the way you get data out of it is a set of decisions worth showing.

## Why 55 files and not 2

Two campaigns, partitioned because WONDER would not return either one whole.

**51 files, one per state plus the District of Columbia.** Named `Race_Ed_Age_Year_*`. The finest grain in the project: state by mother's race by education by age cohort by year. The full cross-tabulation for all states at once exceeds what WONDER will return in a session, so the query was run once per state with the state's name in the title field. The nine files carrying `State_D1` and `State_D2` in their names are the New England and Mid-Atlantic census divisions; the query is the same one.

**4 files, one per census region.** Named `State_MotherSingleRace_Year_*`. The coarser grain: state by mother's race by year, which is what `fct_birth_outcomes` is built from. Four partitions were enough at this grain.

Partitioning is not incidental. Grouping order changes what WONDER returns and whether it returns anything at all, and putting the partition name in the title field is what makes 55 result files identifiable afterwards.

## What is in the footers

Each file ends with the query date, the suggested citation, and the caveats CDC attaches to that particular query. The caveats are not boilerplate and they are worth reading.

Caveat 4 in the state-level files lists every reporting area whose education and prenatal care data is coded "Excluded", and through which year, because those states were still on the 1989 birth certificate. Caveat 7 records that single race categories do not exist before 2016. Together those two footnotes are the reason this study runs from 2016 rather than 2007, and the evidence for that decision is inside the data files rather than in someone's notes.

The other caveats matter for reading the numbers: ages of 12 and under are coded to 12 and ages of 50 and over to 50, births with unknown birth weight are excluded from the birth weight average, and births with unknown gestation are excluded from the gestational age average.

## Format

The `.xls` extension is CDC's. The files are tab-delimited text and open in any text editor or with `pandas.read_csv(..., sep='\t')`. They are not Excel workbooks.

## Reproducing a pull

Dataset D66, "Natality, 2007-2024", at https://wonder.cdc.gov/natality-current.html.

The data use agreement gate re-appears on any fresh navigation to that page, so work from the Request Form tab once you are through it. Measures are not selected by default: only Births is pre-checked, and Average Birth Weight, its standard deviation, and Percent of Total have to be ticked each time. Set the timeout generously; these queries take minutes, not seconds.
