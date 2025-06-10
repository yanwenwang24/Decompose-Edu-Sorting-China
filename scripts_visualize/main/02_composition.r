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

edu_comp_pooled <- read_parquet("outputs/tables/pooled/edu_comp.parquet")
edu_comp_by_urban <- read_parquet("outputs/tables/urban-rural/edu_comp.parquet")

# Recode education and urban status
edu_comp_pooled <- edu_comp_pooled %>%
  mutate(
    Education = case_when(
      Education == 1 ~ "Primary or less",
      Education == 2 ~ "Middle",
      Education == 3 ~ "Secondary",
      Education == 4 ~ "College or higher"
    ),
    Education = factor(Education,
      levels = c(
        "Primary or less", "Middle",
        "Secondary", "College or higher"
      )
    )
  ) %>%
  # Add labels for visualization
  mutate(label = paste0(round(value * 100, 1), "%")) %>%
  select(cohort, Gender, Education, value, label) %>%
  arrange(cohort, Gender, Education, value, label)

edu_comp_by_urban <- edu_comp_by_urban %>%
  mutate(
    Education = case_when(
      Education == 1 ~ "Primary or less",
      Education == 2 ~ "Middle",
      Education == 3 ~ "Secondary",
      Education == 4 ~ "College or higher"
    ),
    Education = factor(Education,
      levels = c(
        "Primary or less", "Middle",
        "Secondary", "College or higher"
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
    aes(
      label = ifelse(value > 0.025, label, ""),
      # Conditionally map color based on Education level
      color = Education %in% c("Secondary", "College or higher")
    ),
    position = position_fill(vjust = 0.5),
    size = 3,
    show.legend = FALSE
  ) +
  scale_fill_manual(
    values = c(
      "#82cfff", "#1192e8", "#00539a", "#012749"
    )
  ) +
  scale_color_manual(
    values = c("TRUE" = "white", "FALSE" = "black")
  ) +
  scale_y_continuous(
    labels = scales::percent,
    limits = c(0, 1),       # Set a common y-axis range
    breaks = seq(0, 1, by = 1)
  ) +
  labs(
    title = "",
    x = "",
    y = ""
  ) +
  theme(legend.position = "none") +
  facet_grid(~Gender)

# By urban
edu_comp_by_urban_plt <- edu_comp_by_urban %>%
  ggplot(aes(x = cohort, y = value, fill = Education)) +
  geom_bar(position = "fill", stat = "identity") +
  geom_text(
    aes(
      label = ifelse(value > 0.025, label, ""),
      # Conditionally map color based on Education level
      color = Education %in% c("Secondary", "College or higher")
    ),
    position = position_fill(vjust = 0.5),
    size = 3,
    show.legend = FALSE
  ) +
  scale_y_continuous(
    labels = scales::percent,
    limits = c(0, 1),       # Set a common y-axis range
    breaks = seq(0, 1, by = 1)
  ) +
  scale_fill_manual(
    values = c(
      "#82cfff", "#1192e8", "#00539a", "#012749"
    )
  ) +
  scale_color_manual(
    values = c("TRUE" = "white", "FALSE" = "black")
  ) +
  labs(
    title = "",
    x = "",
    y = ""
  ) +
  theme(legend.position = "bottom") +
  facet_grid(~ urban + Gender)

edu_comp_plt <- edu_comp_pooled_plt / edu_comp_by_urban_plt

# Save the plot
ggsave(
  "outputs/graphs/main/edu_comp.png",
  edu_comp_plt,
  width = 8,
  height = 12,
  dpi = 300
)
