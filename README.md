# Online-Retail-Cohort-Analysis
A detailed cohort analysis of the Online Retail II dataset (UCI ML Repository) for a UK-based online gift retailer (Dec 2009 - Dec 2011). This repo features R code to compute retention, churn, and revenue trends, with visualizations (heatmaps, trend lines) offering insights into customer behavior. 


# E-commerce Cohort Analysis with R

> **A comprehensive end-to-end cohort analysis of customer retention and revenue patterns using real e-commerce data**

[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![ggplot2](https://img.shields.io/badge/ggplot2-visualization-green.svg)](https://ggplot2.tidyverse.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Project Overview

This project demonstrates a complete cohort analysis workflow using the `cohorts` package in R, analyzing customer behavior patterns from a UK-based online retailer. The analysis tracks customer retention, churn, and revenue patterns over time, providing actionable business insights through beautiful Material Design visualizations.

## Dataset Description

### **Online Retail II Dataset**
- **Source**: [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/machine-learning-databases/00502/online_retail_II.xlsx)
- **Business Context**: UK-based online retailer specializing in unique all-occasion gift items
- **Time Period**: December 1, 2009 - December 9, 2011 (2 years)
- **Size**: 525,461 transactions from 4,312 unique customers
- **Total Revenue**: $8,832,003

### **Data Schema**

| Column | Type | Description | Business Meaning |
|--------|------|-------------|------------------|
| **Invoice** | Character | 6-digit transaction ID (prefix 'c' = cancellation) | Order identifier |
| **StockCode** | Character | 5-digit product identifier | Product SKU |
| **Description** | Character | Product name/description | Item details |
| **Quantity** | Numeric | Number of items purchased | Purchase volume |
| **InvoiceDate** | POSIXct | Transaction timestamp | Purchase timing |
| **Price** | Numeric | Unit price in GBP (£) | Product pricing |
| **Customer ID** | Numeric | Unique customer identifier | Customer tracking |
| **Country** | Character | Customer's country | Geographic segmentation |

## What is Cohort Analysis?

Cohort analysis is a behavioral analytics technique that groups customers by shared characteristics or experiences within a defined time span. In this analysis, we group customers by their **first purchase month** (acquisition cohort) and track their behavior over subsequent months.

### **Key Metrics Tracked:**
- **Retention Rate**: Percentage of customers who return to make purchases
- **Churn Rate**: Percentage of customers who stop purchasing (1 - Retention Rate)
- **Revenue per Customer**: Average revenue generated per customer over time
- **Period-over-Period Churn**: Monthly churn rates for each cohort

### **Why Cohort Analysis Matters:**
- **Identify customer lifecycle patterns**
- **Calculate Customer Lifetime Value (CLV)**
- **Optimize marketing and retention strategies**
- **Track product-market fit over time**
- **Compare performance across different customer segments**

## Methodology

### **1. Data Preprocessing**
```r
# Clean and filter data
retail_clean <- data %>%
  filter(!is.na(`Customer ID`), 
         !is.na(InvoiceDate),
         Quantity > 0,
         Price > 0) %>%
  mutate(
    InvoiceDate = as.Date(InvoiceDate),
    Revenue = Quantity * Price,
    YearMonth = floor_date(InvoiceDate, "month")
  )
```

### **2. Cohort Definition**
- **Cohort**: Customers grouped by first purchase month
- **Cohort Month 0**: Initial purchase month (100% retention by definition)
- **Cohort Month N**: N months after first purchase

### **3. Analysis Framework**
1. **Customer Segmentation**: Group customers by acquisition month
2. **Retention Tracking**: Calculate monthly retention rates for each cohort
3. **Churn Analysis**: Measure customer loss patterns
4. **Revenue Analysis**: Track average revenue per user (ARPU) over time
5. **Trend Analysis**: Identify patterns across cohorts


## Visualizations

Retention Heatmap: 

A heatmap showing the percentage of customers retained over time for each cohort, with green (100% retention) transitioning to red (low retention, e.g., 25%). The x-axis represents months since the first purchase, and the y-axis lists cohort periods (e.g., 2009-12 to 2010-12), with text labels indicating exact retention percentages.

Revenue Heatmap: 

A heatmap displaying the average revenue per customer in GBP, with orange shades indicating higher revenue (up to $800) and lighter shades showing lower revenue. The x-axis denotes months since the first purchase, and the y-axis lists cohort periods, with text labels showing revenue values.


Churn Heatmap (Cumulative):
A heatmap illustrating cumulative churn rates, with green (0% churn) transitioning to red (100% churn). The x-axis represents month numbers, the y-axis lists cohort first purchase months, and text labels display exact churn percentages.

Period-over-Period Churn Heatmap: 

A heatmap mapping churn rates between consecutive months, with green (negative churn, e.g., -27.3%) to red (high churn) color coding. The x-axis shows month numbers, the y-axis lists cohort periods, and text labels indicate period churn rates.


Churn Trend Line: 

A red line graph plotting the average churn rate across all cohorts over time, with dark red data points labeled by percentage (e.g., 77.8% at Month 1). The x-axis represents month numbers, and the y-axis shows the average churn rate.


Cohort Size Distribution:  

A bar chart with steel blue bars representing the number of customers per cohort, peaking at 955 in December 2009. The x-axis lists cohort months, the y-axis shows the number of customers, and text labels display exact counts.



## Key Findings

### **Overall Performance Metrics**
- **Total Customers**: 4,312
- **Analysis Period**: 374 days (Dec 2009 - Dec 2010)
- **Total Revenue**: $8,832,003
- **Average Order Value**: ~$168

### **Retention Performance**

| Month | Average Retention Rate | Business Implication |
|-------|----------------------|---------------------|
| Month 0 | 100.0% | Baseline (all customers) |
| Month 1 | 22.2% | **High initial churn** - 77.8% customers don't return |
| Month 2 | 22.1% | Retention stabilizes around 22% |
| Month 3 | 24.8% | Slight improvement in Month 3 |
| Month 4 | 23.6% | Consistent retention pattern |
| Month 5 | 24.1% | Steady retention around 24% |

### **Churn Analysis**

| Month | Average Churn Rate | Customer Impact |
|-------|-------------------|-----------------|
| Month 1 | 77.8% | **Critical**: Lose ~4/5 customers immediately |
| Month 2 | 77.9% | Cumulative churn remains high |
| Month 3 | 75.2% | Slight improvement but still concerning |
| Month 4 | 76.4% | Consistent high churn pattern |
| Month 5 | 75.9% | Long-term churn stabilizes ~76% |

### **Revenue Patterns**
- **Highest ARPU**: December 2009 cohort ($719 initial, $398 Month 3)
- **Declining Trend**: Later cohorts show lower initial revenue
- **Revenue Retention**: Returning customers maintain decent spending levels

## Visualizations

The analysis includes six comprehensive visualizations:

1. **Customer Retention Heatmap** - Month-by-month retention rates
2. **Revenue per Customer Heatmap** - Average revenue patterns
3. **Cohort Size Distribution** - Customer acquisition over time
4. **Customer Churn Heatmap** - Cumulative churn rates
5. **Period-over-Period Churn** - Monthly churn patterns
6. **Churn Trend Analysis** - Overall churn progression

## Business Implications

### **Critical Issues Identified**

1. **Massive First-Month Churn (77.8%)**
   - **Problem**: Losing almost 4 out of 5 customers after first purchase
   - **Impact**: Severe impact on Customer Lifetime Value
   - **Action**: Urgent need for onboarding and early engagement strategies

2. **Low Long-term Retention (~24%)**
   - **Problem**: Only 1 in 4 customers become repeat buyers
   - **Impact**: Heavy reliance on new customer acquisition
   - **Action**: Implement loyalty programs and personalized marketing

3. **Revenue Decline in Later Cohorts**
   - **Problem**: Newer customers spending less than earlier cohorts
   - **Impact**: Decreasing average order values over time
   - **Action**: Review pricing strategy and product mix

### **Strategic Recommendations**

#### **Immediate Actions (0-3 months)**
- **Welcome Series**: Implement email sequence for new customers
- **First Purchase Follow-up**: Targeted communication within 48 hours
- **Customer Support**: Proactive outreach to first-time buyers
- **Product Recommendations**: Personalized suggestions based on initial purchase

#### **Medium-term Initiatives (3-6 months)**
- **Loyalty Program**: Reward repeat purchases and referrals
- **Segmented Marketing**: Different strategies for each cohort performance level
- **Product Bundling**: Increase average order value
- **Customer Feedback**: Survey churned customers to understand reasons

#### **Long-term Strategy (6+ months)**
- **Predictive Analytics**: Build churn prediction models
- **Lifetime Value Optimization**: Focus on high-value customer segments
- **Market Expansion**: Explore new customer acquisition channels
- **Product Development**: Create products that drive repeat purchases

### **Expected Impact of Improvements**

| Improvement | Current State | Target State | Revenue Impact |
|-------------|---------------|--------------|----------------|
| Month 1 Retention | 22.2% | 35% (+57%) | +$1.1M annually |
| Month 3 Retention | 24.8% | 40% (+61%) | +$800K annually |
| Average Order Value | $168 | $200 (+19%) | +$1.7M annually |
| **Total Potential** | | | **+$3.6M annually** |

## Technical Implementation

### **Required Libraries**
```r
library(cohorts)      # Cohort analysis functions
library(dplyr)        # Data manipulation
library(ggplot2)      # Visualization
library(lubridate)    # Date handling
library(readxl)       # Excel file reading
library(scales)       # Number formatting
```

### **Key Functions Used**
- `floor_date()`: Group dates by month
- `n_distinct()`: Count unique customers
- `pivot_wider()`: Create cohort matrices
- `geom_tile()`: Create heatmaps
- Material Design color palette for professional visualizations

### **Code Structure**
1. **Data Loading & Cleaning** (Lines 1-30)
2. **Cohort Construction** (Lines 31-50)
3. **Retention Analysis** (Lines 51-80)
4. **Churn Analysis** (Lines 81-120)
5. **Revenue Analysis** (Lines 121-140)
6. **Visualization Creation** (Lines 141-280)
7. **Insights Generation** (Lines 281-320)

## Design Principles

### **Material Design Implementation**
- **Color Palette**: Professional Material Design colors
- **Typography**: Clean, readable font hierarchy
- **Data Labels**: High contrast, appropriately sized
- **Minimalism**: Clean layouts with essential information only

### **Chart Types & Rationale**
- **Heatmaps**: Ideal for showing patterns across two dimensions (cohort × time)
- **Bar Charts**: Clear representation of cohort sizes
- **Line Charts**: Effective for showing trends over time
- **Consistent Styling**: Unified visual language across all charts

## Getting Started

### **Prerequisites**
- R 4.0+
- Required packages (see Technical Implementation)

### **Quick Start**
1. Clone this repository
2. Install required packages: `install.packages(c("cohorts", "dplyr", "ggplot2", "lubridate", "readxl", "scales"))`
3. Run the analysis script
4. View generated visualizations and insights

### **Data Source**
The script automatically downloads data from:
```
https://archive.ics.uci.edu/ml/machine-learning-databases/00502/online_retail_II.xlsx
```

## 📝 Key Takeaways

1. **Customer retention is the biggest challenge** - 77.8% first-month churn rate
2. **Revenue patterns vary significantly** between early and late cohorts
3. **Gift retail business model** requires special attention to seasonal patterns
4. **Data-driven approach** reveals actionable insights for business improvement
5. **Visual analytics** make complex patterns immediately understandable



*This analysis demonstrates the power of cohort analysis in understanding customer behavior and driving business decisions.*
