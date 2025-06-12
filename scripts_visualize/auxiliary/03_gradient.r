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

gradient_pooled <- read_parquet(
  "outputs/tables/auxiliary/pooled/gradients.parquet"
)
gradient_by_urban <- read_parquet(
  "outputs/tables/auxiliary/urban-rural/gradients.parquet"
)

# Recode education and urban status
gradient_pooled <- gradient_pooled %>%
  mutate(
    Education = case_when(
      edu5 == 1 ~ "Primary or less",
      edu5 == 2 ~ "Middle",
      edu5 == 3 ~ "Secondary",
      edu5 == 4 ~ "Some college",
      edu5 == 5 ~ "College or above"
    ),
    Education = factor(Education,
      levels = c(
        "Primary or less", "Middle",
        "Secondary", "Some college", "College or above"
      )
    )
  )

gradient_by_urban <- gradient_by_urban %>%
  mutate(
    Education = case_when(
      edu5 == 1 ~ "Primary or less",
      edu5 == 2 ~ "Middle",
      edu5 == 3 ~ "Secondary",
      edu5 == 4 ~ "Some college",
      edu5 == 5 ~ "College or above"
    ),
    Education = factor(Education,
      levels = c(
        "Primary or less", "Middle",
        "Secondary", "Some college", "College or above"
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
      "#bae6ff", "#33b1ff", "#0072c3", "#003a6d", "#1c0f30"
    )
  ) +
  labs(
    x = "",
    y = "Odds of being unmarried"
  ) +
  facet_grid(~Gender) +
  theme(
    legend.position = "none",
    axis.title.y = element_text(angle = 90)
  )

# By urban
gradient_by_urban_plt <- ggplot(
  gradient_by_urban,
  aes(x = birthy, y = ratio, color = Education, group = Education)
) +
  geom_point(alpha = 0.75) +
  geom_smooth(span = 0.8, se = FALSE) +
  scale_color_manual(
    values = c(
      "#bae6ff", "#33b1ff", "#0072c3", "#003a6d", "#1c0f30"
    )
  ) +
  labs(
    x = "",
    y = "Odds of being unmarried"
  ) +
  facet_grid(~ urban + Gender) +
  theme(
    legend.position = "bottom",
    axis.title.y = element_text(angle = 90)
  )

gradient_plt <- gradient_pooled_plt / gradient_by_urban_plt

# Save the plot
ggsave(
  "outputs/graphs/auxiliary/gradient.png",
  gradient_plt,
  width = 9,
  height = 12,
  dpi = 300
)
