# Marketing Campaign A/B Testing Analysis — SQL & Python

---

## Overview

An end-to-end A/B testing framework that evaluates the performance of two marketing campaigns using SQL-based funnel metric computation and Python-based statistical hypothesis testing. The analysis determines whether the observed difference in conversion rates between the control and test campaigns is statistically significant — supporting data-driven budget and strategy decisions.

---

## Business Problem

Running two campaign variants costs money. Without statistical validation, there's no way to know if performance differences are real or just random noise. This project answers:

- **Which campaign drives more conversions?**
- **Is the difference statistically significant (not just by chance)?**
- **Where in the funnel does the test campaign outperform control?**
- **Should we scale the test campaign or stick with control?**

---

## Dataset

| Column | Description |
|--------|-------------|
| Campaign Name | Control Campaign / Test Campaign |
| Date | Date of the campaign activity |
| Spend (USD) | Amount spent on the campaign |
| Impressions | Number of times ad was shown |
| Reach | Unique users who saw the ad |
| Website Clicks | Users who clicked through to the website |
| Searches | Number of searches performed |
| Content Views | Product/content pages viewed |
| Add to Cart | Items added to cart |
| Purchases | Completed transactions |

---

## Funnel Architecture

```
Impressions
     ↓
Website Clicks      → CTR = Clicks / Impressions
     ↓
Content Views       → View Rate = Views / Clicks
     ↓
Add to Cart         → Cart Rate = Add-to-Cart / Views
     ↓
Purchases           → Conversion Rate = Purchases / Clicks
                    → Revenue per User = Revenue / Reach
```

---

## Methodology

### Step 1 — Data Preparation
- Loaded campaign dataset and inspected for nulls and inconsistencies
- Applied **mean imputation** for missing values in numeric columns
- Verified data types and standardized column names

### Step 2 — SQL Funnel Analysis

Computed key funnel metrics at the database level using SQL:

```sql
-- Click-Through Rate (CTR)
SELECT
    campaign_name,
    SUM(website_clicks) AS total_clicks,
    SUM(impressions)    AS total_impressions,
    ROUND(SUM(website_clicks) * 100.0 / SUM(impressions), 2) AS ctr
FROM campaigns
GROUP BY campaign_name;

-- Conversion Rate
SELECT
    campaign_name,
    SUM(purchases)      AS total_purchases,
    SUM(website_clicks) AS total_clicks,
    ROUND(SUM(purchases) * 100.0 / SUM(website_clicks), 2) AS conversion_rate
FROM campaigns
GROUP BY campaign_name;

-- Add-to-Cart Rate
SELECT
    campaign_name,
    ROUND(SUM(add_to_cart) * 100.0 / SUM(content_views), 2) AS cart_rate
FROM campaigns
GROUP BY campaign_name;

-- Revenue per User
SELECT
    campaign_name,
    ROUND(SUM(spend_usd) * 1.0 / SUM(reach), 4) AS revenue_per_user
FROM campaigns
GROUP BY campaign_name;
```

### Step 3 — Python Statistical Testing

Applied **two-sample t-test** to determine if the difference in conversion rates between campaigns is statistically significant:

```python
from scipy import stats

control = df[df['campaign_name'] == 'Control Campaign']['purchases']
test    = df[df['campaign_name'] == 'Test Campaign']['purchases']

# Two-sample t-test
t_stat, p_value = stats.ttest_ind(control, test)

alpha = 0.05
print(f"T-statistic: {t_stat:.4f}")
print(f"P-value:     {p_value:.4f}")

if p_value < alpha:
    print("Result: REJECT H₀ — Statistically significant difference detected")
else:
    print("Result: FAIL TO REJECT H₀ — No statistically significant difference")
```

**Hypotheses:**
- **H₀ (Null):** No difference in conversion performance between Control and Test campaigns
- **H₁ (Alternative):** The Test campaign performs significantly better than Control

### Step 4 — EDA & Visualization
- Compared metric distributions across campaigns using bar charts and box plots
- Visualized the full conversion funnel for both groups
- Analyzed day-level trends in clicks, add-to-cart, and purchases

---

## Key Metrics Comparison

| Metric | Control Campaign | Test Campaign | Winner |
|--------|-----------------|---------------|--------|
| Impressions | Higher reach | Lower reach | Control |
| CTR (Click-Through Rate) | Baseline | Higher | **Test** |
| Add-to-Cart Rate | Baseline | Higher | **Test** |
| Conversion Rate | Baseline | Higher | **Test** |
| Revenue per User | Baseline | Higher | **Test** |

---

## Statistical Test Results

| Parameter | Value |
|-----------|-------|
| Test Used | Two-sample t-test (independent groups) |
| Significance Level (α) | 0.05 |
| Result | Statistically significant difference detected |
| Decision | **Reject H₀** — Test campaign outperforms Control |

> The test campaign shows significantly higher conversion rates across funnel stages. The difference is not due to random variation — it reflects a genuine performance improvement.

---

## Key Insights

- The **Test campaign** outperforms the Control campaign at every stage of the conversion funnel — clicks, add-to-cart, and purchases
- **CTR is higher** for the Test campaign — the ad creative drives more clicks per impression
- **Add-to-cart rate is higher** — Test campaign attracts more purchase-intent users
- **Conversion rate difference is statistically significant** — safe to act on, not random noise
- **Revenue per user is higher** in the Test campaign — better return on ad spend (ROAS)

---

## Project Structure

```
├── marketing_campaign_ab_testing_analysis.ipynb   # Main notebook — EDA + stats testing
├── sql/                                           # SQL queries folder
│   └── ab_test_queries.sql                        # Funnel metric SQL queries
└── README.md                                      # Project documentation
```

---

## How to Run

```bash
# 1. Clone the repository
git clone https://github.com/ramubattu321/A-B-Testing-Analysis-using-SQL-and-Python.git
cd A-B-Testing-Analysis-using-SQL-and-Python

# 2. Install dependencies
pip install pandas numpy matplotlib scipy jupyter

# 3. Open the notebook
jupyter notebook marketing_campaign_ab_testing_analysis.ipynb

# 4. To run SQL queries
# Open sql/ab_test_queries.sql in any SQL client
# (MySQL Workbench, DBeaver, SQLite, etc.)
```

---

## Business Impact

- **Campaign selection** — statistical evidence confirms the Test campaign should be scaled
- **Budget optimization** — reallocate spend from Control to the higher-performing Test variant
- **Funnel diagnosis** — pinpoints exactly where the Test campaign outperforms (CTR, cart, conversion)
- **Risk reduction** — statistical significance eliminates guesswork from campaign decisions
- **Reusable framework** — SQL + Python pipeline applicable to any future A/B experiment

---

## Tools & Technologies

| Tool | Purpose |
|------|---------|
| Python | Statistical testing and EDA |
| Pandas | Data loading, cleaning, aggregation |
| NumPy | Numerical operations |
| SciPy (`ttest_ind`) | Two-sample t-test for significance testing |
| Matplotlib | Funnel and comparison visualizations |
| SQL | Funnel metric computation (CTR, conversion rate, revenue/user) |
| Jupyter Notebook | Interactive analysis environment |

---

## Applications

- Marketing campaign performance evaluation
- Conversion rate optimization (CRO)
- Product feature experimentation
- Pricing and promotion A/B testing
- Customer behavior analysis across segments

---

## Author
Ramu Battu

**Ramu Battu**
MS in Data Analytics — California State University, Fresno
📧 ramuusa61@gmail.com
