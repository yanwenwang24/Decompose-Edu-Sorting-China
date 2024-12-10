## ------------------------------------------------------------------------
##
## Script name: 03_gradient.r
## Purpose: Visualize educational gradients in marriage rates
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

gradient_pooled <- read_feather("Outputs/gradients.arrow")
gradient_by_hukou <- read_feather("Outputs_by_hukou/gradients.arrow")

# Recode education and urban status
gradient_pooled <- gradient_pooled %>%
  mutate(
    Education = case_when(
      edu == 1 ~ "Primary or lower",
      edu == 2 ~ "Middle school",
      edu == 3 ~ "High school",
      edu == 4 ~ "College or higher"
    ),
    Education = factor(Education,
      levels = c(
        "Primary or lower", "Middle school",
        "High school", "College or higher"
      )
    )
  )

gradient_by_hukou <- gradient_by_hukou %>%
  mutate(
    Education = case_when(
      edu == 1 ~ "Primary or lower",
      edu == 2 ~ "Middle school",
      edu == 3 ~ "High school",
      edu == 4 ~ "College or higher"
    ),
    Education = factor(Education,
      levels = c(
        "Primary or lower", "Middle school",
        "High school", "College or higher"
      )
    )
  ) %>%
  mutate(urban = ifelse(urban == 1, "Rural", "Urban"))


# 2 Plot trends -----------------------------------------------------------

# Pooled
gradient_pooled_plt <- ggplot(
  gradient_pooled,
  aes(x = birthy, y = ratio, color = Education, group = Education)
) +
  geom_point(alpha = 0.75) +
  geom_smooth(span = 0.8, se = FALSE) +
  scale_color_manual(
    values = c(
      "#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe",
      "#ffb55a", "#ffee65", "#beb9db", "#fdcce5", "#8bd3c7"
    )
  ) +
  labs(
    x = "Cohort",
    y = "Ratio of unmarried to married"
  ) +
  theme(legend.position = "none") +
  facet_grid(~Gender)

# By hukou
gradient_by_hukou_plt <- ggplot(
  gradient_by_hukou,
  aes(x = birthy, y = ratio, color = Education, group = Education)
) +
  geom_point(alpha = 0.75) +
  geom_smooth(span = 0.8, se = FALSE) +
  scale_color_manual(
    values = c(
      "#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe",
      "#ffb55a", "#ffee65", "#beb9db", "#fdcce5", "#8bd3c7"
    )
  ) +
  labs(
    x = "Cohort",
    y = "Ratio of unmarried to married"
  ) +
  theme(legend.position = "bottom") +
  facet_grid(~urban+Gender)

gradient_plt <- gradient_pooled_plt / gradient_by_hukou_plt

# Save the plot
ggsave(
  "Graphs/gradient.png",
  gradient_plt,
  width = 8,
  height = 12,
  dpi = 300
)
