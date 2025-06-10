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

odds_ratio_pooled <- read_parquet("outputs/tables/pooled/odds_ratio.parquet")
odds_ratio_by_urban <- read_parquet(
  "outputs/tables/urban-rural/odds_ratio.parquet"
)

# Recode education and urban status
odds_ratio_pooled <- odds_ratio_pooled %>%
  mutate(
    Education = factor(edu,
      levels = c(
        "Primary or less",
        "Middle",
        "Secondary",
        "College or above",
        "Aggregated"
      )
    )
  )

odds_ratio_by_urban <- odds_ratio_by_urban %>%
  mutate(
    Education = factor(edu,
      levels = c(
        "Primary or less",
        "Middle",
        "Secondary",
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
      "Primary or less" = "#82cfff",
      "Middle" = "#1192e8",
      "Secondary" = "#00539a",
      "College or above" = "#012749",
      "Aggregated" = "grey"
    ),
    name = "Education"
  ) +
  scale_linetype_manual(
    values = c(
      "Primary or less" = "solid",
      "Middle" = "solid",
      "Secondary" = "solid",
      "College or above" = "solid",
      "Aggregated" = "dashed"
    ),
    name = "Education"
  ) +
  labs(
    x = "",
    y = "Log-odd ratios"
  ) +
  facet_grid(~term) +
  theme(
    legend.position = "none",
    axis.title.y = element_text(angle = 90)
  )

# By urban
odds_ratio_by_urban_plt <- odds_ratio_by_urban %>%
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
      "Primary or less" = "#82cfff",
      "Middle" = "#1192e8",
      "Secondary" = "#00539a",
      "College or above" = "#012749",
      "Aggregated" = "grey"
    ),
    name = "Education"
  ) +
  scale_linetype_manual(
    values = c(
      "Primary or less" = "solid",
      "Middle" = "solid",
      "Secondary" = "solid",
      "College or above" = "solid",
      "Aggregated" = "dashed"
    ),
    name = "Education"
  ) +
  labs(
    x = "",
    y = "Log-odd ratios"
  ) +
  facet_grid(~ term + urban) +
  theme(
    legend.position = "bottom",
    axis.title.y = element_text(angle = 90)
  )

odds_ratio_plt <- odds_ratio_pooled_plt / odds_ratio_by_urban_plt

# Save the plot
ggsave(
  "outputs/graphs/main/odds_ratio.png",
  odds_ratio_plt,
  width = 8,
  height = 12,
  dpi = 300
)
