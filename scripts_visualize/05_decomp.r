## ------------------------------------------------------------------------
##
## Script name: 04_decomp.r
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

decomp_pooled <- read_feather("Outputs/decomp.arrow")
decomp_by_hukou <- read_feather("Outputs_by_hukou/decomp.arrow")

# Recode
decomp_pooled <- decomp_pooled %>%
  filter(group != base_group) %>%
  filter(component != "total") %>%
  mutate(pattern = str_to_title(pattern)) %>%
  mutate(
    component = case_when(
      component == "expansion" ~ "Educational expansion",
      component == "gradient" ~ "Educational gradient",
      component == "pattern" ~ "Assortative mating"
    ),
    component = factor(
      component,
      levels = c(
        "Educational expansion",
        "Educational gradient",
        "Assortative mating"
      )
    )
  )

decomp_by_hukou <- decomp_by_hukou %>%
  filter(group != base_group) %>%
  filter(component != "total") %>%
  mutate(pattern = str_to_title(pattern)) %>%
  mutate(
    component = case_when(
      component == "expansion" ~ "Educational expansion",
      component == "gradient" ~ "Educational gradient",
      component == "pattern" ~ "Assortative mating"
    ),
    component = factor(
      component,
      levels = c(
        "Educational expansion",
        "Educational gradient",
        "Assortative mating"
      )
    )
  )

# 2 Plot trends -----------------------------------------------------------

# Pooled
decomp_pooled_plt <- decomp_pooled %>%
  ggplot(aes(
    x = group, y = estimate,
    fill = component, group = component, linetype = component
  )) +
  geom_bar(position = "stack", stat = "identity") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    values = c(
      "#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe",
      "#ffb55a", "#ffee65", "#beb9db", "#fdcce5", "#8bd3c7"
    )
  ) +
  labs(
    y = "",
    x = "Cohort"
  ) +
  theme(legend.position = "none") +
  facet_grid(~pattern)

# By hukou
decomp_by_hukou_plt <- decomp_by_hukou %>%
  ggplot(aes(x = cohort, y = estimate, fill = component)) +
  geom_bar(position = "stack", stat = "identity") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    values = c(
      "#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe",
      "#ffb55a", "#ffee65", "#beb9db", "#fdcce5", "#8bd3c7"
    )
  ) +
  labs(
    y = "",
    x = "Cohort"
  ) +
  facet_wrap(~pattern, nrow = 1) +
  theme_bw() +
  theme(
    legend.title = element_blank(),
    legend.position = "bottom"
  )

decomp_plt <- decomp_pooled_plt / decomp_by_hukou_plt

# Save the plot
ggsave(
  "Graphs/decomp.png",
  decomp_plt,
  width = 8,
  height = 12,
  dpi = 300
)
