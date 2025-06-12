# Decompose-Edu-Sorting-China

Replication package for:

Wang, Yanwen, and Zheng Mu. "Understanding Trends in Marital Sorting by Education in China: A Decomposition Approach". (Major Revision, *Demography*).

## Abstract

Over the past decades, the patterns of educational sorting in marriage have changed dramatically in China, exhibiting a U-shaped curve for homogamy, an inverted U-shaped curve for hypergamy, and a consistently low prevalence of hypogamy. However, few studies have systematically examined why these changes occurred as they did. Using data from China’s Censuses (1982–2010), this study employs a decomposition approach to unpack the contributions of three driving forces: educational expansion, educational gradients in marriage rates, and assortative mating propensities. Results show that the initial decrease in homogamy among cohorts born before 1965 was driven entirely by educational expansion. For later birth cohorts, sustained educational expansion promoted homogamy and hypogamy while discouraging hypergamy, outweighing the opposing effects of a steeper decline in marriage rates among highly educated women. Mating propensities favoring homogamy and against heterogamy, especially hypogamy, intensified. Collectively, these three factors explain the rising homogamy, declining hypergamy, and stagnant hypogamy across later cohorts, as well as the persistent, though narrowing, urban-rural disparities.

*Keywords*: education, assortative mating, educational expansion, marriage, China

## Important note

Census 2010 data is not available on [IPUMS International](https://international.ipums.org/international/) due to regulatory restrictions and cannot be disclosed. Please adjust sample selection and analysis scripts accordingly to exclude this dataset.

## Replication procedures

After installing Julia, R, and relevant packages, follow these steps to replicate the study:

1. Download China's Census in 1982, 1990, and 2000 from [IPUMS International](https://international.ipums.org/international/).
2. Clean data using the scripts in the [scripts_tidy](./scripts_tidy/) directory.
3. Decompose differences in educational sorting outcomes across cohorts using scripts in the [scripts_analysis/pooled](./scripts_analysis/pooled/) directory.
4. Decompose differences in educational sorting outcomes between urban and rural areas by cohort using scripts in the [scripts_analysis/urban-rural](./scripts_analysis/urban-rural/) directory.
5. Visualize the results using scripts in the [scripts_visualize](./scripts_visualize/) directory.
6. Auxiliary analyses using five-level education classification are in the [scripts_analysis/auxiliary](./scripts_analysis/auxiliary/) directory.
