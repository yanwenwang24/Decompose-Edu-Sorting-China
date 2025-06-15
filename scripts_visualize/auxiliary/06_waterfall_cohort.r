## ------------------------------------------------------------------------
##
## Script name: 06_waterfall_cohort.r
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

decomp_pooled <- read_parquet("outputs/tables/auxiliary/pooled/decomp.parquet")

# Print output
decomp_pooled %>%
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
  select(group, pattern, component, estimate, se, sign) %>%
  print(n = Inf)

# Recode
decomp_pooled <- decomp_pooled %>%
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

prepare_waterfall_data <- function(df, pattern_name) {
  # Calculate sequential change
  deltas <- df %>%
    filter(pattern == pattern_name) %>%
    group_by(component) %>%
    arrange(group) %>%
    mutate(sequential_change = estimate - lag(estimate, default = 0)) %>%
    ungroup()

  cohorts <- unique(deltas$group) %>% sort()
  base_cohort <- unique(df$base_group)

  waterfall_list <- list()
  cumulative_total <- 0

  for (i in seq_along(cohorts)) {
    current_cohort <- cohorts[i]
    previous_cohort <- if (i == 1) base_cohort else cohorts[i - 1]

    component_changes <- deltas %>% filter(group == current_cohort)

    start_bar <- tibble(
      facet_group = paste(previous_cohort, "to", current_cohort),
      label = "Start", value = cumulative_total, type = "total"
    )
    component_bars_loop <- tibble(
      facet_group = paste(previous_cohort, "to", current_cohort),
      label = as.character(component_changes$component),
      value = component_changes$sequential_change, type = "component"
    )
    waterfall_list[[i]] <- bind_rows(start_bar, component_bars_loop)
    cumulative_total <- cumulative_total + sum(component_bars_loop$value)
  }

  # Calculate plotting coordinates and return the final component bars
  bind_rows(waterfall_list) %>%
    mutate(
      facet_group = fct_inorder(facet_group),
      label = factor(
        label,
        levels = c("Start", "Edu expansion", "Edu gradient", "Assort mating")
      )
    ) %>%
    group_by(facet_group) %>%
    mutate(end = cumsum(value), start = lag(end, default = 0)) %>%
    ungroup() %>%
    filter(type == "component")
}

all_component_bars <- bind_rows(
  mutate(
    prepare_waterfall_data(decomp_pooled, "Homogamy"),
    pattern = "Homogamy"
  ),
  mutate(
    prepare_waterfall_data(decomp_pooled, "Hypergamy"),
    pattern = "Hypergamy"
  ),
  mutate(
    prepare_waterfall_data(decomp_pooled, "Hypogamy"),
    pattern = "Hypogamy"
  )
) %>%
  mutate(
    pattern = factor(
      pattern,
      levels = c("Homogamy", "Hypergamy", "Hypogamy")
    )
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
    padded_min = min_y - 0.005,
    padded_max = max_y + 0.005
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
  # Layer 0: Blank y-axis to set limits and connecting lines
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
  "outputs/graphs/auxiliary/waterfall_cohort.png",
  waterfall_integrated_plt,
  width = 9.5,
  height = 12,
  dpi = 300
)
