## ------------------------------------------------------------------------
##
## Script name: 05_odds_ratio.r
## Purpose: Odds ratio analysis
## Author: Yanwen Wang
## Date Created: 2024-12-08
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
library(marginaleffects)
library(tidyverse)

sample_women_married <- read_parquet(
  "data/samples/pooled/sample_women_married.parquet"
)

# 1 Contingency tables ----------------------------------------------------

data <- sample_women_married %>%
  group_by(cohort, edu5_f, edu5_m) %>%
  summarise(n = n()) %>%
  ungroup() %>%
  mutate(
    homo = ifelse(edu5_f == edu5_m, 1, 0),
    hyper = ifelse(edu5_f < edu5_m, 1, 0),
    hypo = ifelse(edu5_f > edu5_m, 1, 0)
  ) %>%
  mutate(
    edu5_f = factor(edu5_f),
    edu5_m = factor(edu5_m)
  )

# 2 Log-linear model ------------------------------------------------------

# 2.1 Aggregated ----------------------------------------------------------

# Homogamy
mod_homo_agg <- glm(
  n ~ edu5_f * cohort + edu5_m * cohort +
    homo * cohort,
  data = data,
  family = poisson
)

homo_agg_df <- avg_comparisons(
  mod_homo_agg,
  variables = c("homo"),
  by = "cohort",
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  select(term, cohort, estimate, conf.high, conf.low)

# Hypergamy
mod_hyper_agg <- glm(
  n ~ edu5_f * cohort + edu5_m * cohort +
    hyper * cohort,
  data = data,
  family = poisson
)

hyper_agg_df <- avg_comparisons(
  mod_hyper_agg,
  variables = c("hyper"),
  by = "cohort",
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  select(term, cohort, estimate, conf.high, conf.low)

# Hypogamy
mod_hypo_agg <- glm(
  n ~ edu5_f * cohort + edu5_m * cohort +
    hypo * cohort,
  data = data,
  family = poisson
)

hypo_agg_df <- avg_comparisons(
  mod_hypo_agg,
  variables = c("hypo"),
  by = "cohort",
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  select(term, cohort, estimate, conf.high, conf.low)

# Merge coefficients
agg_df <- bind_rows(
  homo_agg_df, hyper_agg_df, hypo_agg_df
) %>%
  mutate(edu = "Aggregated")

# 2.2 By education ---------------------------------------------------------

# Homogamy
mod_homo_edu <- glm(
  n ~ edu5_f * cohort + edu5_m * cohort +
    homo * cohort + homo * edu5_f * cohort,
  data = data,
  family = poisson
)

homo_edu_df <- avg_comparisons(
  mod_homo_edu,
  variables = c("homo"),
  by = c("cohort", "edu5_f"),
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  select(term, cohort, edu5_f, estimate, conf.high, conf.low)

# Hypergamy
mod_hyper_edu <- glm(
  n ~ edu5_f * cohort + edu5_m * cohort +
    hyper * cohort + hyper * edu5_f * cohort,
  data = data,
  family = poisson
)

hyper_edu_df <- avg_comparisons(
  mod_hyper_edu,
  variables = c("hyper"),
  by = c("cohort", "edu5_f"),
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  select(term, cohort, edu5_f, estimate, conf.high, conf.low)

# Hypogamy
mod_hypo_edu <- glm(
  n ~ edu5_f * cohort + edu5_m * cohort +
    hypo * cohort + hypo * edu5_f * cohort,
  data = data,
  family = poisson
)

hypo_edu_df <- avg_comparisons(
  mod_hypo_edu,
  variables = c("hypo"),
  by = c("cohort", "edu5_f"),
  comparison = "lnratio"
) %>%
  as.data.frame() %>%
  select(term, cohort, edu5_f, estimate, conf.high, conf.low)

# Merge coefficients
by_edu_df <- bind_rows(
  homo_edu_df, hyper_edu_df, hypo_edu_df
) %>%
  # Remove rank deficient
  filter(
    !(term == "hyper" & edu5_f == 5),
    !(term == "hypo" & edu5_f == 1)
  ) %>%
  rename(edu = edu5_f)

# Merge df aggregated and by education
odds_ratio <- bind_rows(
  agg_df, by_edu_df
) %>%
  mutate(
    edu = case_when(
      edu == "Aggregated" ~ "Aggregated",
      edu == "1" ~ "Primary or less",
      edu == "2" ~ "Middle",
      edu == "3" ~ "Secondary",
      edu == "4" ~ "Some college",
      edu == "5" ~ "College or above"
    ),
    term = case_when(
      term == "homo" ~ "Homogamy",
      term == "hyper" ~ "Hypergamy",
      term == "hypo" ~ "Hypogamy"
    )
  )

write_parquet(odds_ratio, "outputs/tables/pooled/odds_ratio.parquet")
