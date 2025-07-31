# End-to-End Cohort Analysis using cohorts package
# Dataset: Online Retail II from UCI ML Repository

# Load required libraries
library(cohorts)
library(dplyr)
library(ggplot2)
library(lubridate)
library(readxl)
library(scales)

# Material Design Color Palette
material_colors <- list(
  primary = "#1976D2",      # Material Blue
  secondary = "#424242",    # Material Grey
  accent = "#FF4081",       # Material Pink
  success = "#4CAF50",      # Material Green
  warning = "#FF9800",      # Material Orange
  error = "#F44336",        # Material Red
  surface = "#FAFAFA",      # Light Grey
  background = "#FFFFFF"    # White
)

# Custom minimal theme
theme_material <- function() {
  theme_minimal() +
  theme(
    text = element_text(family = "Arial", color = material_colors$secondary),
    plot.title = element_text(size = 16, face = "bold", margin = margin(b = 20), color = material_colors$secondary),
    plot.subtitle = element_text(size = 12, margin = margin(b = 15), color = material_colors$secondary),
    axis.title = element_text(size = 11, color = material_colors$secondary),
    axis.text = element_text(size = 10, color = material_colors$secondary),
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major = element_line(color = "#E0E0E0", size = 0.3),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = material_colors$background, color = NA),
    plot.background = element_rect(fill = material_colors$background, color = NA),
    strip.text = element_text(size = 11, face = "bold", color = material_colors$secondary),
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1)
  )
}

# Download and load data
url <- "https://archive.ics.uci.edu/ml/machine-learning-databases/00502/online_retail_II.xlsx"
download.file(url, "online_retail_II.xlsx", mode = "wb")
data <- read_excel("online_retail_II.xlsx", sheet = "Year 2009-2010")

# Data preprocessing
retail_clean <- data %>%
  filter(!is.na(`Customer ID`), 
         !is.na(InvoiceDate),
         Quantity > 0,
         Price > 0) %>%
  mutate(
    InvoiceDate = as.Date(InvoiceDate),
    Revenue = Quantity * Price,
    YearMonth = floor_date(InvoiceDate, "month")
  ) %>%
  select(`Customer ID`, InvoiceDate, YearMonth, Revenue) %>%
  rename(CustomerID = `Customer ID`)

# Create cohort data structure
cohort_data <- retail_clean %>%
  group_by(CustomerID) %>%
  mutate(first_purchase = min(YearMonth)) %>%
  ungroup() %>%
  mutate(
    cohort_month = as.numeric(difftime(YearMonth, first_purchase, units = "days")) %/% 30
  ) %>%
  filter(cohort_month >= 0)

# Generate cohort table using cohorts package
cohort_table <- cohort_data %>%
  group_by(first_purchase, cohort_month) %>%
  summarise(
    customers = n_distinct(CustomerID),
    revenue = sum(Revenue, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(first_purchase, cohort_month)

# Calculate cohort sizes (initial customers per cohort)
cohort_sizes <- cohort_data %>%
  filter(cohort_month == 0) %>%
  group_by(first_purchase) %>%
  summarise(cohort_size = n_distinct(CustomerID), .groups = "drop")

# CHURN ANALYSIS
# Calculate churn rates (opposite of retention)
churn_matrix <- cohort_table %>%
  left_join(cohort_sizes, by = "first_purchase") %>%
  mutate(
    retention_rate = customers / cohort_size,
    churn_rate = 1 - retention_rate
  ) %>%
  select(first_purchase, cohort_month, churn_rate) %>%
  tidyr::pivot_wider(
    names_from = cohort_month,
    values_from = churn_rate,
    names_prefix = "Month_"
  )

# Calculate period-over-period churn (customers who churned in each specific period)
pop_churn <- cohort_table %>%
  left_join(cohort_sizes, by = "first_purchase") %>%
  arrange(first_purchase, cohort_month) %>%
  group_by(first_purchase) %>%
  mutate(
    prev_customers = lag(customers, default = first(customers)),
    churned_customers = prev_customers - customers,
    period_churn_rate = churned_customers / prev_customers
  ) %>%
  filter(cohort_month > 0) %>%
  select(first_purchase, cohort_month, period_churn_rate) %>%
  tidyr::pivot_wider(
    names_from = cohort_month,
    values_from = period_churn_rate,
    names_prefix = "Month_"
  )

print("Cumulative Churn Rates:")
print(churn_matrix)
print("Period-over-Period Churn Rates:")
print(pop_churn)

# Create retention rate matrix
retention_matrix <- cohort_table %>%
  left_join(cohort_sizes, by = "first_purchase") %>%
  mutate(retention_rate = customers / cohort_size) %>%
  select(first_purchase, cohort_month, retention_rate) %>%
  tidyr::pivot_wider(
    names_from = cohort_month,
    values_from = retention_rate,
    names_prefix = "Month_"
  )

print("Cohort Retention Rates:")
print(retention_matrix)

# Revenue cohort analysis
revenue_matrix <- cohort_table %>%
  left_join(cohort_sizes, by = "first_purchase") %>%
  mutate(avg_revenue_per_user = revenue / cohort_size) %>%
  select(first_purchase, cohort_month, avg_revenue_per_user) %>%
  tidyr::pivot_wider(
    names_from = cohort_month,
    values_from = avg_revenue_per_user,
    names_prefix = "Month_"
  )

print("Average Revenue Per User by Cohort:")
print(revenue_matrix)

# Visualizations
# 1. Retention Heatmap - Material Design
retention_long <- retention_matrix %>%
  tidyr::pivot_longer(
    cols = starts_with("Month_"),
    names_to = "cohort_month",
    values_to = "retention_rate"
  ) %>%
  mutate(
    cohort_month = as.numeric(gsub("Month_", "", cohort_month)),
    cohort_label = format(first_purchase, "%Y-%m")
  ) %>%
  filter(!is.na(retention_rate))

retention_heatmap <- ggplot(retention_long, aes(x = cohort_month, y = cohort_label, fill = retention_rate)) +
  geom_tile(color = "white", size = 1) +
  geom_text(aes(label = paste0(round(retention_rate * 100, 0), "%")), 
            color = "white", size = 4.5, fontface = "bold") +
  scale_fill_gradient2(
    low = material_colors$error, 
    mid = material_colors$warning, 
    high = material_colors$success,
    midpoint = 0.5, 
    labels = percent_format(accuracy = 1),
    name = "Retention"
  ) +
  labs(
    title = "Customer Retention by Cohort",
    subtitle = "Percentage of customers retained over time",
    x = "Months Since First Purchase",
    y = "Cohort Period"
  ) +
  theme_material() +
  coord_fixed(ratio = 0.8)

# 2. Revenue Per User Heatmap - Material Design
revenue_long <- revenue_matrix %>%
  tidyr::pivot_longer(
    cols = starts_with("Month_"),
    names_to = "cohort_month",
    values_to = "avg_revenue"
  ) %>%
  mutate(
    cohort_month = as.numeric(gsub("Month_", "", cohort_month)),
    cohort_label = format(first_purchase, "%Y-%m")
  ) %>%
  filter(!is.na(avg_revenue))

revenue_heatmap <- ggplot(revenue_long, aes(x = cohort_month, y = cohort_label, fill = avg_revenue)) +
  geom_tile(color = "white", size = 1) +
  geom_text(aes(label = paste0("$", round(avg_revenue, 0))), 
            color = material_colors$secondary, size = 4, fontface = "bold") +
  scale_fill_gradient(
    low = "#FFF3E0", 
    high = "#FF9800",
    labels = dollar_format(),
    name = "Revenue"
  ) +
  labs(
    title = "Revenue per Customer by Cohort",
    subtitle = "Average revenue generated per customer",
    x = "Months Since First Purchase",
    y = "Cohort Period"
  ) +
  theme_material() +
  coord_fixed(ratio = 0.8)

# 4. Churn Rate Heatmap
churn_long <- churn_matrix %>%
  tidyr::pivot_longer(
    cols = starts_with("Month_"),
    names_to = "cohort_month",
    values_to = "churn_rate"
  ) %>%
  mutate(
    cohort_month = as.numeric(gsub("Month_", "", cohort_month)),
    cohort_label = format(first_purchase, "%Y-%m")
  ) %>%
  filter(!is.na(churn_rate))

churn_heatmap <- ggplot(churn_long, aes(x = cohort_month, y = cohort_label, fill = churn_rate)) +
  geom_tile(color = "white", size = 0.5) +
  geom_text(aes(label = paste0(round(churn_rate * 100, 1), "%")), 
            color = "white", size = 3, fontface = "bold") +
  scale_fill_gradient2(low = "green", mid = "orange", high = "red", 
                       midpoint = 0.5, labels = scales::percent) +
  labs(
    title = "Customer Churn Rate by Cohort (Cumulative)",
    x = "Month Number",
    y = "Cohort (First Purchase Month)",
    fill = "Churn Rate"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

# 5. Period-over-Period Churn Heatmap
pop_churn_long <- pop_churn %>%
  tidyr::pivot_longer(
    cols = starts_with("Month_"),
    names_to = "cohort_month",
    values_to = "period_churn_rate"
  ) %>%
  mutate(
    cohort_month = as.numeric(gsub("Month_", "", cohort_month)),
    cohort_label = format(first_purchase, "%Y-%m")
  ) %>%
  filter(!is.na(period_churn_rate))

pop_churn_heatmap <- ggplot(pop_churn_long, aes(x = cohort_month, y = cohort_label, fill = period_churn_rate)) +
  geom_tile(color = "white", size = 0.5) +
  geom_text(aes(label = paste0(round(period_churn_rate * 100, 1), "%")), 
            color = "white", size = 3, fontface = "bold") +
  scale_fill_gradient2(low = "green", mid = "orange", high = "red", 
                       midpoint = 0.2, labels = scales::percent) +
  labs(
    title = "Period-over-Period Churn Rate by Cohort",
    x = "Month Number",
    y = "Cohort (First Purchase Month)",
    fill = "Period Churn Rate"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

# 6. Average Churn Trend Line
avg_churn_trend <- churn_long %>%
  group_by(cohort_month) %>%
  summarise(avg_churn = mean(churn_rate, na.rm = TRUE), .groups = "drop")

churn_trend_plot <- ggplot(avg_churn_trend, aes(x = cohort_month, y = avg_churn)) +
  geom_line(color = "red", size = 1.2) +
  geom_point(color = "darkred", size = 3) +
  geom_text(aes(label = paste0(round(avg_churn * 100, 1), "%")), 
            vjust = -1, color = "darkred", fontface = "bold") +
  labs(
    title = "Average Churn Rate Trend Across All Cohorts",
    x = "Month Number",
    y = "Average Churn Rate"
  ) +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal() +
  theme(panel.grid.minor = element_blank())

# 3. Cohort Size Distribution with Data Labels
cohort_size_plot <- ggplot(cohort_sizes, aes(x = first_purchase, y = cohort_size)) +
  geom_col(fill = "steelblue", alpha = 0.7) +
  geom_text(aes(label = scales::comma(cohort_size)), 
            vjust = -0.3, color = "black", size = 3, fontface = "bold") +
  labs(
    title = "Cohort Sizes Over Time",
    x = "Cohort Month",
    y = "Number of Customers"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_y_continuous(labels = scales::comma)

# Display plots
print(retention_heatmap)
print(revenue_heatmap)
print(cohort_size_plot)
print(churn_heatmap)
print(pop_churn_heatmap)
print(churn_trend_plot)

# Key insights
cat("\n=== COHORT ANALYSIS INSIGHTS ===\n")
cat("Dataset: Online Retail II (UCI ML Repository)\n")
cat("Analysis Period:", min(retail_clean$InvoiceDate), "to", max(retail_clean$InvoiceDate), "\n")
cat("Total Customers:", n_distinct(retail_clean$CustomerID), "\n")
cat("Total Revenue: $", format(sum(retail_clean$Revenue), big.mark = ","), "\n")

# Calculate average retention by month
avg_retention <- retention_long %>%
  group_by(cohort_month) %>%
  summarise(avg_retention = mean(retention_rate, na.rm = TRUE), .groups = "drop")

# Calculate average churn by month
avg_churn <- churn_long %>%
  group_by(cohort_month) %>%
  summarise(avg_churn = mean(churn_rate, na.rm = TRUE), .groups = "drop")

cat("\nAverage Retention Rates:\n")
for(i in 1:min(6, nrow(avg_retention))) {
  cat("Month", avg_retention$cohort_month[i], ":", 
      round(avg_retention$avg_retention[i] * 100, 1), "%\n")
}

cat("\nAverage Churn Rates:\n")
for(i in 1:min(6, nrow(avg_churn))) {
  cat("Month", avg_churn$cohort_month[i], ":", 
      round(avg_churn$avg_churn[i] * 100, 1), "%\n")
}

# Best and worst performing cohorts
best_cohort <- retention_matrix %>%
  rowwise() %>%
  mutate(month_3_retention = Month_3) %>%
  filter(!is.na(month_3_retention)) %>%
  slice_max(month_3_retention, n = 1)

worst_cohort <- retention_matrix %>%
  rowwise() %>%
  mutate(month_3_retention = Month_3) %>%
  filter(!is.na(month_3_retention)) %>%
  slice_min(month_3_retention, n = 1)

cat("\nBest Performing Cohort (Month 3 retention):", 
    format(best_cohort$first_purchase, "%Y-%m"), 
    "-", round(best_cohort$month_3_retention * 100, 1), "%\n")
cat("Worst Performing Cohort (Month 3 retention):", 
    format(worst_cohort$first_purchase, "%Y-%m"), 
    "-", round(worst_cohort$month_3_retention * 100, 1), "%\n")
