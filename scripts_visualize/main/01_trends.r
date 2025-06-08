## ------------------------------------------------------------------------
##
## Script name: 01_trends.r
## Purpose: Visualize trends in educational sorting outcomes in marriage
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

trends_pooled <- read_parquet("outputs/tables/pooled/trends.parquet")
trends_by_urban <- read_parquet("outputs/tables/urban-rural/trends.parquet")

# Recode urban
trends_by_urban$urban <- ifelse(
  trends_by_urban$urban == 1, "Rural", "Urban"
)

# 2 Plot trends -----------------------------------------------------------

# Trends pooled
trends_pooled_plt <- trends_pooled %>%
  ggplot(aes(x = birthy, y = Proportion, color = Pattern, shape = Type)) +
  geom_point(alpha = 0.5) +
  geom_smooth(aes(linetype = Type), se = FALSE) +
  scale_x_continuous(
    breaks = seq(
      min(trends_pooled$birthy), max(trends_pooled$birthy),
      by = 5
    )
  ) +
  scale_y_continuous(labels = scales::percent) +
  scale_color_manual(
    values = c(
      "#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe",
      "#ffb55a", "#ffee65", "#beb9db", "#fdcce5", "#8bd3c7"
    )
  ) +
  labs(
    title = "",
    x = "Cohort",
    y = ""
  ) +
  theme(legend.position = "none")

# Trends by urban
trends_by_urban_plt <- trends_by_urban %>%
  ggplot(aes(x = birthy, y = Proportion, color = Pattern, shape = Type)) +
  geom_point(alpha = 0.5) +
  geom_smooth(aes(linetype = Type), se = FALSE) +
  scale_x_continuous(
    breaks = seq(
      min(trends_by_urban$birthy), max(trends_by_urban$birthy),
      by = 5
    )
  ) +
  scale_y_continuous(labels = scales::percent) +
  scale_color_manual(
    values = c(
      "#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe",
      "#ffb55a", "#ffee65", "#beb9db", "#fdcce5", "#8bd3c7"
    )
  ) +
  labs(
    title = "",
    x = "Cohort",
    y = "",
  ) +
  facet_grid(~urban)

trends_plt <- trends_pooled_plt + trends_by_urban_plt

# Save the plot
ggsave(
  "outputs/graphs/main/trends.png",
  trends_plt,
  width = 10,
  height = 10,
  dpi = 300
)
