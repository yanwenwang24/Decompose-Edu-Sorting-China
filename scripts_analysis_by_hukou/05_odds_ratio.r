## ------------------------------------------------------------------------
##
## Script name: 05_odds_ratio.r
## Purpose: Odds ratio analysis
## Author: Yanwen Wang
## Date Created: 2024-12-09
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Compute changes in odds ratio for homogamy, hypergamy, and Hypogamy
## across cohorts (both aggregated and varied across educational levels)
##
## ------------------------------------------------------------------------

# Load packages -----------------------------------------------------------

library(arrow)
library(glm)
library(marginaleffects)
library(tidyverse)

sample <- read_feather("Samples_by_hukou/sample.arrow")

# 1 Contingency tables ----------------------------------------------------

data <- sample %>%
  group_by(urban, cohort, edu_f, edu_m) %>%
  summarise(n = n()) %>%
  ungroup() %>%
  mutate(
    homo = ifelse(edu_f == edu_m, 1, 0),
    hyper = ifelse(edu_f < edu_m, 1, 0),
    hypo = ifelse(edu_f > edu_m, 1, 0)
  ) %>%
  mutate(
    edu_f = factor(edu_f),
    edu_m = factor(edu_m)
  )

data_rural <- filter(data, urban == 1)
data_urban <- filter(data, urban == 2)

# 2 Log-linear model ------------------------------------------------------

# 2.1 Aggregated ----------------------------------------------------------

# Homogamy
## Rural
mod_homo_agg_rural <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    homo * cohort,
  data = data_rural,
  family = poisson
)

homo_agg_rural_df <- avg_comparisons(
  mod_homo_agg_rural,
  variables = c("homo"),
  by = "cohort",
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 1) %>%
  select(urban, term, cohort, estimate, conf.high, conf.low)

## Urban
mod_homo_agg_urban <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    homo * cohort,
  data = data_urban,
  family = poisson
)

homo_agg_urban_df <- avg_comparisons(
  mod_homo_agg_urban,
  variables = c("homo"),
  by = "cohort",
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 2) %>%
  select(urban, term, cohort, estimate, conf.high, conf.low)

# Hypergamy
## Rural
mod_hyper_agg_rural <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    hyper * cohort,
  data = data_rural,
  family = poisson
)

hyper_agg_rural_df <- avg_comparisons(
  mod_hyper_agg_rural,
  variables = c("hyper"),
  by = "cohort",
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 1) %>%
  select(urban, term, cohort, estimate, conf.high, conf.low)

## Urban
mod_hyper_agg_urban <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    hyper * cohort,
  data = data_urban,
  family = poisson
)

hyper_agg_urban_df <- avg_comparisons(
  mod_hyper_agg_urban,
  variables = c("hyper"),
  by = "cohort",
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 2) %>%
  select(urban, term, cohort, estimate, conf.high, conf.low)

# Hypogamy
## Rural
mod_hypo_agg_rural <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    hypo * cohort,
  data = data_rural,
  family = poisson
)

hypo_agg_rural_df <- avg_comparisons(
  mod_hypo_agg_rural,
  variables = c("hypo"),
  by = "cohort",
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 1) %>%
  select(urban, term, cohort, estimate, conf.high, conf.low)

## Urban
mod_hypo_agg_urban <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    hypo * cohort,
  data = data_urban,
  family = poisson
)

hypo_agg_urban_df <- avg_comparisons(
  mod_hypo_agg_urban,
  variables = c("hypo"),
  by = "cohort",
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 2) %>%
  select(urban, term, cohort, estimate, conf.high, conf.low)

# Merge coefficients
agg_df <- bind_rows(
  homo_agg_rural_df, homo_agg_urban_df,
  hyper_agg_rural_df, hyper_agg_urban_df,
  hypo_agg_rural_df, hypo_agg_urban_df,
) %>%
  mutate(edu = "Aggregated")

# 2.2 By education ---------------------------------------------------------

# Homogamy
## Rural
mod_homo_edu_rural <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    homo * cohort + homo * edu_f * cohort,
  data = data_rural,
  family = poisson
)

homo_edu_rural_df <- avg_comparisons(
  mod_homo_edu_rural,
  variables = c("homo"),
  by = c("cohort", "edu_f"),
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 1) %>%
  select(urban, term, cohort, edu_f, estimate, conf.high, conf.low)

## Urban
mod_homo_edu_urban <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    homo * cohort + homo * edu_f * cohort,
  data = data_urban,
  family = poisson
)

homo_edu_urban_df <- avg_comparisons(
  mod_homo_edu_urban,
  variables = c("homo"),
  by = c("cohort", "edu_f"),
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 2) %>%
  select(urban, term, cohort, edu_f, estimate, conf.high, conf.low)

# Hypergamy
## Rural
mod_hyper_edu_rural <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    hyper * cohort + hyper * edu_f * cohort,
  data = data_rural,
  family = poisson
)

hyper_edu_rural_df <- avg_comparisons(
  mod_hyper_edu_rural,
  variables = c("hyper"),
  by = c("cohort", "edu_f"),
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 1) %>%
  select(urban, term, cohort, edu_f, estimate, conf.high, conf.low)

## Urban
mod_hyper_edu_urban <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    hyper * cohort + hyper * edu_f * cohort,
  data = data_urban,
  family = poisson
)

hyper_edu_urban_df <- avg_comparisons(
  mod_hyper_edu_urban,
  variables = c("hyper"),
  by = c("cohort", "edu_f"),
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 2) %>%
  select(urban, term, cohort, edu_f, estimate, conf.high, conf.low)

# Hypogamy
## Rural
mod_hypo_edu_rural <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    hypo * cohort + hypo * edu_f * cohort,
  data = data_rural,
  family = poisson
)

hypo_edu_rural_df <- avg_comparisons(
  mod_hypo_edu_rural,
  variables = c("hypo"),
  by = c("cohort", "edu_f"),
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 1) %>%
  select(urban, term, cohort, edu_f, estimate, conf.high, conf.low)

## Urban
mod_hypo_edu_urban <- glm(
  n ~ edu_f * cohort + edu_m * cohort +
    hypo * cohort + hypo * edu_f * cohort,
  data = data_urban,
  family = poisson
)

hypo_edu_urban_df <- avg_comparisons(
  mod_hypo_edu_urban,
  variables = c("hypo"),
  by = c("cohort", "edu_f"),
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  mutate(urban = 2) %>%
  select(urban, term, cohort, edu_f, estimate, conf.high, conf.low)

# Merge coefficients
by_edu_df <- bind_rows(
  homo_edu_rural_df, homo_edu_urban_df,
  hyper_edu_rural_df, hyper_edu_urban_df,
  hypo_edu_rural_df, hypo_edu_urban_df
) %>%
  # Remove rank deficient
  filter(
    !(term == "hyper" & edu_f == 4),
    !(term == "hypo" & edu_f == 1)
  ) %>%
  rename(edu = edu_f)

# Merge df aggregated and by education
odds_ratio <- bind_rows(
  agg_df, by_edu_df
) %>%
  mutate(
    edu = case_when(
      edu == "Aggregated" ~ "Aggregated",
      edu == "1" ~ "Primary or less",
      edu == "2" ~ "Middle",
      edu == "3" ~ "High",
      edu == "4" ~ "College or above"
    ),
    term = case_when(
      term == "homo" ~ "Homogamy",
      term == "hyper" ~ "Hypergamy",
      term == "hypo" ~ "Hypogamy"
    )
  )

write_feather(odds_ratio, "Outputs_by_hukou/odds_ratio.arrow")
