## ------------------------------------------------------------------------
##
## Script name: 02_composition.r
## Purpose: Visualize educational composition across cohorts
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

edu_comp_pooled <- read_feather("Outputs/edu_comp.arrow")
edu_comp_by_hukou <- read_feather("Outputs_by_hukou/edu_comp.arrow")

# Recode education and urban status
edu_comp_pooled <- edu_comp_pooled %>%
  mutate(
    Education = case_when(
      Education == 1 ~ "Primary or lower",
      Education == 2 ~ "Middle school",
      Education == 3 ~ "High school",
      Education == 4 ~ "College or higher"
    ),
    Education = factor(Education,
      levels = c(
        "Primary or lower", "Middle school",
        "High school", "College or higher"
      )
    )
  ) %>%
  # Add labels for visualization
  mutate(label = paste0(round(value * 100, 1), "%")) %>%
  select(cohort, Gender, Education, value, label) %>%
  arrange(cohort, Gender, Education, value, label)

edu_comp_by_hukou <- edu_comp_by_hukou %>%
  mutate(
    Education = case_when(
      Education == 1 ~ "Primary or lower",
      Education == 2 ~ "Middle school",
      Education == 3 ~ "High school",
      Education == 4 ~ "College or higher"
    ),
    Education = factor(Education,
      levels = c(
        "Primary or lower", "Middle school",
        "High school", "College or higher"
      )
    )
  ) %>%
  mutate(urban = ifelse(urban == 1, "Rural", "Urban")) %>%
  # Add labels for visualization
  mutate(label = paste0(round(value * 100, 1), "%")) %>%
  select(urban, cohort, Gender, Education, value, label) %>%
  arrange(urban, cohort, Gender, Education, value, label)


# 2 Plot trends -----------------------------------------------------------

# Pooled
edu_comp_pooled_plt <- ggplot(
  edu_comp_pooled,
  aes(x = cohort, y = value, fill = Education)
) +
  geom_bar(position = "fill", stat = "identity") +
  geom_text(
    aes(label = label),
    position = position_fill(vjust = 0.5),
    size = 3
  ) +
  scale_fill_manual(
    values = c(
      "#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe",
      "#ffb55a", "#ffee65", "#beb9db", "#fdcce5", "#8bd3c7"
    )
  ) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "",
    x = "Cohort",
    y = ""
  ) +
  theme(legend.position = "none") +
  facet_grid(~Gender)

# By hukou
edu_comp_by_hukou_plt <- edu_comp_by_hukou %>%
  ggplot(aes(x = cohort, y = value, fill = Education)) +
  geom_bar(position = "fill", stat = "identity") +
  geom_text(
    aes(label = label),
    position = position_fill(vjust = 0.5),
    size = 3
  ) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
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
  theme_bw() +
  theme(legend.position = "bottom") +
  facet_grid(~ urban + Gender)

edu_comp_plt <- edu_comp_pooled_plt / edu_comp_by_hukou_plt

# Save the plot
ggsave(
  "Graphs/edu_comp.png",
  edu_comp_plt,
  width = 8,
  height = 12,
  dpi = 300
)
