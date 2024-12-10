## ------------------------------------------------------------------------
##
## Script name: 04_odds_ratio.r
## Purpose: Visualize odds ratios
## Author: Yanwen Wang
## Date Created: 2024-12-10
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Load data -------------------------------------------------------------

odds_ratio_pooled <- read_feather("Outputs/odds_ratio.arrow")
odds_ratio_by_hukou <- read_feather("Outputs_by_hukou/odds_ratio.arrow")

# Recode education and urban status
odds_ratio_pooled <- odds_ratio_pooled %>%
  mutate(
    Education = factor(edu,
      levels = c(
        "Primary or less",
        "Middle",
        "High",
        "College or above",
        "Aggregated"
      )
    )
  )

odds_ratio_by_hukou <- odds_ratio_by_hukou %>%
  mutate(
    Education = factor(edu,
      levels = c(
        "Primary or less",
        "Middle",
        "High",
        "College or above",
        "Aggregated"
      )
    )
  ) %>%
  mutate(urban = ifelse(urban == 1, "Rural", "Urban"))

# 2 Plot trends -----------------------------------------------------------

# Pooled
odds_ratio_pooled_plt <- odds_ratio_pooled %>%
  ggplot(aes(
    x = cohort, y = estimate,
    color = Education, group = Education, linetype = Education
  )) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey") +
  scale_y_continuous(breaks = seq(-10, 10, by = 1)) +
  scale_color_manual(
    values = c(
      "Primary or less" = "#fd7f6f",
      "Middle" = "#7eb0d5",
      "High" = "#b2e061",
      "College or above" = "#bd7ebe",
      "Aggregated" = "grey"
    ),
    name = "Education"
  ) +
  scale_linetype_manual(
    values = c(
      "Primary or less" = "solid",
      "Middle" = "solid",
      "High" = "solid",
      "College or above" = "solid",
      "Aggregated" = "dashed"
    ),
    name = "Education"
  ) +
  labs(
    x = "Cohort",
    y = "Log-odd ratios"
  ) +
  theme(legend.position = "none") +
  facet_grid(~term)

# By hukou
odds_ratio_by_hukou_plt <- odds_ratio_by_hukou %>%
  ggplot(aes(
    x = cohort, y = estimate,
    color = Education, group = Education, linetype = Education
  )) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey") +
  scale_y_continuous(breaks = seq(-10, 10, by = 1)) +
  scale_color_manual(
    values = c(
      "Primary or less" = "#fd7f6f",
      "Middle" = "#7eb0d5",
      "High" = "#b2e061",
      "College or above" = "#bd7ebe",
      "Aggregated" = "grey"
    ),
    name = "Education"
  ) +
  scale_linetype_manual(
    values = c(
      "Primary or less" = "solid",
      "Middle" = "solid",
      "High" = "solid",
      "College or above" = "solid",
      "Aggregated" = "dashed"
    ),
    name = "Education"
  ) +
  labs(
    x = "Cohort",
    y = "Log-odd ratios"
  ) +
  theme(legend.position = "bottom") +
  facet_grid(~term+urban)

odds_ratio_plt <- odds_ratio_pooled_plt / odds_ratio_by_hukou_plt

# Save the plot
ggsave(
  "Graphs/odds_ratio.png",
  odds_ratio_plt,
  width = 8,
  height = 12,
  dpi = 300
)
