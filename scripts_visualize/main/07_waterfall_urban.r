## ------------------------------------------------------------------------
##
## Script name: 07_waterfall_urban.r
## Purpose: Visualize odds ratios
## Author: Yanwen Wang
## Date Created: 2025-06-15
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Load data -------------------------------------------------------------

decomp_by_urban <- read_parquet("outputs/tables/urban-rural/decomp.parquet")

# Print output
decomp_by_urban %>%
  filter(group != base_group) %>%
  mutate(
    p_value = 2 * pnorm(-abs(estimate / se))
  ) %>%
  mutate(
    sign = case_when(
      p_value < 0.001 ~ "***",
      p_value < 0.01 ~ "**",
      p_value < 0.05 ~ "*",
      TRUE ~ "ns"
    )
  ) %>%
  select(cohort, group, pattern, component, estimate, se, sign) %>%
  print(n = Inf)

decomp_by_urban <- decomp_by_urban %>%
  filter(group != base_group) %>%
  filter(component != "total") %>%
  mutate(pattern = str_to_title(pattern)) %>%
  mutate(
    component = case_when(
      component == "expansion" ~ "Edu expansion",
      component == "gradient" ~ "Edu gradient",
      component == "pattern" ~ "Assort mating"
    ),
    component = factor(
      component,
      levels = c(
        "Edu expansion",
        "Edu gradient",
        "Assort mating"
      )
    )
  )

# 2 Prepare data for visualization ----------------------------------------

all_component_bars <- decomp_by_urban %>%
  group_by(pattern, cohort) %>%
  arrange(component) %>%
  # Calculate the start/end points
  mutate(
    end = cumsum(estimate),
    start = lag(end, default = 0)
  ) %>%
  ungroup() %>%
  rename(
    label = component,
    value = estimate,
    facet_group = cohort
  ) %>%
  mutate(
    pattern = factor(pattern, levels = c("Homogamy", "Hypergamy", "Hypogamy")),
    facet_group = fct_inorder(as.character(facet_group))
  )

# 3 Visualization ---------------------------------------------------------

# Set a threshold for label positioning
label_threshold <- 0.01

all_labels_inside <- all_component_bars %>%
  filter(abs(value) >= label_threshold)

all_labels_outside <- all_component_bars %>%
  filter(abs(value) < label_threshold)

# Set y-axis range
y_range_data <- all_component_bars %>%
  mutate(
    # Determine where the outside text labels will go
    text_y_pos = ifelse(abs(value) < label_threshold,
      end + ifelse(value > 0, 0.015, -0.015),
      NA
    )
  ) %>%
  group_by(pattern) %>%
  summarise(
    min_y = min(c(start, end, text_y_pos), na.rm = TRUE),
    max_y = max(c(start, end, text_y_pos), na.rm = TRUE)
  ) %>%
  mutate(
    padded_min = min_y - 0.0025,
    padded_max = max_y + 0.0025
  )

# Reshape this into a 'dummy' dataframe for geom_blank()
dummy_data_for_y_axis <- y_range_data %>%
  select(pattern, padded_min, padded_max) %>%
  tidyr::pivot_longer(
    cols = c(padded_min, padded_max),
    names_to = "type",
    values_to = "y"
  )

# Draw the waterfall plot
waterfall_integrated_plt <- ggplot() +
  # Layer 0: Blank y-axis to set limits
  geom_blank(data = dummy_data_for_y_axis, aes(y = y)) +

  # Layer 1: The Component Bars
  geom_rect(
    data = all_component_bars,
    aes(
      xmin = as.numeric(label) - 0.45,
      xmax = as.numeric(label) + 0.45,
      ymin = start,
      ymax = end,
      fill = label
    )
  ) +

  # Layer 2a: Text labels INSIDE large bars
  geom_text(
    data = all_labels_inside,
    aes(
      x = as.numeric(label),
      y = (start + end) / 2,
      label = sprintf("%+.2f", value),
      color = label
    ),
    size = 2.5
  ) +

  # Layer 2b: Text labels OUTSIDE small bars
  geom_text(
    data = all_labels_outside,
    aes(
      x = as.numeric(label),
      y = end,
      label = sprintf("%+.2f", value),
      vjust = ifelse(value > 0, -0.5, 1.5)
    ),
    color = "black",
    size = 2.5
  ) +

  # Layer 3: Horizontal zero line
  geom_hline(
    yintercept = 0,
    linewidth = 1,
    linetype = "solid",
    color = "darkgrey"
  ) +

  # Facet grid for patterns and cohorts
  facet_grid(
    pattern ~ facet_group,
    scales = "free_y",
    switch = "y"
  ) +

  # Color and fill settings
  scale_color_manual(
    guide = "none",
    values = c(
      "Edu expansion" = "white",
      "Edu gradient" = "white",
      "Assort mating" = "black"
    )
  ) +
  scale_fill_manual(
    name = "",
    values = c(
      "Edu expansion" = "#fd7f6f",
      "Edu gradient"  = "#7eb0d5",
      "Assort mating" = "#b2e061"
    )
  ) +
  labs(
    y = "",
    x = ""
  ) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    strip.text.y.left = element_text(angle = 90),
    strip.placement = "outside",
    legend.position = "right",
    panel.spacing.y = unit(0.8, "lines"),
    panel.spacing.x = unit(0.1, "lines")
  )

ggsave(
  "outputs/graphs/main/waterfall_urban.png",
  waterfall_integrated_plt,
  width = 9.5,
  height = 12,
  dpi = 300
)
