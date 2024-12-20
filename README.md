# Decompose-Edu-Sorting-China

Replication package for:

Wang, Yanwen, and Zheng Mu. "Understanding Trends in Marital Sorting by Education in China: A Decomposition Approach". (Under Review).

## Abstract

Over the past decades, the patterns of educational sorting in marriage have changed dramatically in China, exhibiting a U-shaped curve for homogamy, an inverted U-shaped curve for hypergamy, and a consistently low prevalence of hypogamy. However, few studies have systematically examined why these changes occurred as they did. Using data from China’s Census, this study employs a decomposition approach to unpack the contributions of three driving forces: educational expansion, educational gradients in marriage rates, and assortative mating preferences. Results show that the initial decrease in homogamy among cohorts born before 1965 was driven entirely by educational expansion. For later birth cohorts, sustained educational expansion promoted homogamy and hypogamy while discouraging hypergamy. This influence outweighed the opposing effects of a steeper decline in marriage rates among highly educated women. Preferences for homogamy and against heterogamy, especially hypogamy, intensified. Combined, the three factors explained the rising homogamy, declining hypergamy, and stagnant hypogamy across later cohorts.

*Keywords*:  education, assortative mating, educational expansion, marriage, China

## Important note

Census 2010 data is not available on [IPUMS International](https://international.ipums.org/international/) due to regulatory restrictions and cannot be disclosed. Please adjust sample selection and analysis scripts accordingly to exclude this dataset.

## Replication procedures

Follow these steps to replicate the study:
1. Download China's Census in 1982, 1990, and 2000 from [IPUMS International](https://international.ipums.org/international/).
2. Execute data cleaning procedures using the scripts in the [scripts_tidy](./scripts_tidy/) directory.
3. Conduct the pooled analysis to decompose differences in educational sorting outcomes across cohorts:
    - Navigate to the [scripts_analysis](./scripts_analysis/) directory
    - Results will be generated in the [Outputs](./Outputs/) directory.
4. Perform the stratified analysis to decompose differences in educational sorting outcomes between urban and rural areas by cohort:
    - Navigate to the [scripts_analysis_by_hukou](./scripts_analysis_by_hukou/) directory
    - Results will be generated in the [Outputs_by_hukou](./Outputs_by_hukou/) directory
5. Visualize the results using scripts in the [scripts_visualize](./scripts_visualize/) directory.