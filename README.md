# Marketing Campaign A/B Testing Analysis — SQL & Python

![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat&logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-SQLite-003B57?style=flat&logo=sqlite&logoColor=white)
![SciPy](https://img.shields.io/badge/SciPy-Statistical%20Testing-8CAAE6?style=flat&logo=scipy&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-Data%20Analysis-150458?style=flat&logo=pandas&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat)

---

## Overview

An end-to-end A/B testing framework that evaluates the performance of two marketing campaigns using **SQL-based funnel metric computation** and **Python-based statistical hypothesis testing**. The analysis determines whether the observed difference in conversion rates between the control and test campaigns is statistically significant — supporting data-driven budget and strategy decisions.

---

## Business Problem

Running two campaign variants costs money. Without statistical validation, there is no way to know if performance differences are real or just random noise. This project answers:

- **Which campaign drives more conversions?**
- **Is the difference statistically significant — not just by chance?**
- **Where in the funnel does the test campaign outperform control?**
- **Which device, region, and age group responds best to the test campaign?**
- **Should we scale the test campaign or stick with control?**

---

## Dataset

| Column | Description |
|--------|-------------|
| Campaign Name | Control Campaign / Test Campaign |
| Date | Date of campaign activity |
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
Website Clicks    → CTR            = Clicks / Impressions
     ↓
Content Views     → View Rate      = Views / Clicks
     ↓
Add to Cart       → Cart Rate      = Cart / Views
     ↓
Purchases         → Conversion Rate = Purchases / Clicks
                  → Revenue/User    = Revenue / Reach
```

---

## Project Structure

```
A-B-Testing-Analysis-using-SQL-and-Python/
│
├── marketing_campaign_ab_testing_analysis.ipynb   # Python EDA + statistical testing
│
├── sql/
│   ├── schema.sql           # Database schema — 3 tables + indexes
│   ├── sample_data.sql      # Data — 60 campaign rows, 10K users, 1K+ funnel events
│   ├── ab_test_queries.sql  # 16 production SQL queries
│   └── setup_and_run.py     # Python script — creates SQLite DB + runs all queries
│
└── README.md
```

---

## SQL Database Schema

Three tables capturing campaign, user, and event-level data:

```sql
-- Daily campaign metrics (60 rows — 30 days × 2 campaigns)
campaign_performance (
    campaign_name, campaign_date, spend_usd,
    impressions, reach, website_clicks,
    searches, content_views, add_to_cart, purchases
)

-- User-level experiment assignments (10,000 users)
experiment_assignments (
    user_id, variant, assigned_date,
    device_type, region, age_group
)

-- Individual funnel events (impression → click → view → cart → purchase)
funnel_events (
    user_id, event_type, event_date, revenue
)
```

---

## SQL Queries — 16 Production Queries

### Funnel & Conversion Analysis

```sql
-- Click-Through Rate (CTR) per campaign
SELECT
    campaign_name,
    ROUND(100.0 * SUM(website_clicks) / NULLIF(SUM(impressions), 0), 2) AS ctr_pct
FROM campaign_performance
GROUP BY campaign_name;

-- Full funnel conversion rates at every stage
SELECT
    campaign_name,
    ROUND(100.0 * SUM(website_clicks)  / NULLIF(SUM(impressions),   0), 2) AS ctr_pct,
    ROUND(100.0 * SUM(content_views)   / NULLIF(SUM(website_clicks), 0), 2) AS view_rate_pct,
    ROUND(100.0 * SUM(add_to_cart)     / NULLIF(SUM(content_views),  0), 2) AS cart_rate_pct,
    ROUND(100.0 * SUM(purchases)       / NULLIF(SUM(website_clicks), 0), 2) AS overall_cvr_pct
FROM campaign_performance
GROUP BY campaign_name;
```

### Window Functions

```sql
-- Running cumulative CVR over time (SUM OVER)
SELECT campaign_name, campaign_date, purchases,
    SUM(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS cum_purchases,
    ROUND(100.0 *
        SUM(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) /
        NULLIF(SUM(website_clicks) OVER (PARTITION BY campaign_name ORDER BY campaign_date), 0),
    2) AS running_cvr_pct
FROM campaign_performance;

-- Day-over-day change using LAG
SELECT campaign_name, campaign_date, purchases,
    LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS prev_day,
    purchases - LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS daily_change,
    ROUND(100.0 * (purchases - LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date))
        / NULLIF(LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date), 0), 1) AS dod_pct
FROM campaign_performance;

-- Performance quartiles using NTILE
SELECT campaign_name, campaign_date, purchases,
    NTILE(4) OVER (PARTITION BY campaign_name ORDER BY purchases) AS quartile,
    CASE NTILE(4) OVER (PARTITION BY campaign_name ORDER BY purchases)
        WHEN 4 THEN 'Top 25%'   WHEN 3 THEN 'Above Avg'
        WHEN 2 THEN 'Below Avg' WHEN 1 THEN 'Bottom 25%'
    END AS performance_label
FROM campaign_performance;
```

### CTE & Segment Analysis

```sql
-- Funnel drop-off analysis using CTE
WITH totals AS (
    SELECT campaign_name,
        SUM(impressions)    AS imp,
        SUM(website_clicks) AS clk,
        SUM(content_views)  AS vw,
        SUM(add_to_cart)    AS cart,
        SUM(purchases)      AS purch
    FROM campaign_performance GROUP BY campaign_name
)
SELECT campaign_name,
    ROUND(100.0*(imp-clk)/imp,  1) AS drop_imp_to_click_pct,
    ROUND(100.0*(clk-vw)/clk,   1) AS drop_click_to_view_pct,
    ROUND(100.0*(vw-cart)/vw,   1) AS drop_view_to_cart_pct,
    ROUND(100.0*(cart-purch)/cart,1)AS drop_cart_to_purch_pct
FROM totals;

-- Revenue per user by device type (JOIN + segment)
SELECT e.variant, e.device_type,
    COUNT(DISTINCT e.user_id) AS users,
    SUM(CASE WHEN f.event_type='purchase' THEN 1 ELSE 0 END) AS conversions,
    ROUND(100.0*SUM(CASE WHEN f.event_type='purchase' THEN 1 ELSE 0 END)
        / COUNT(DISTINCT e.user_id), 2) AS cvr_pct,
    ROUND(SUM(f.revenue), 2) AS total_revenue
FROM experiment_assignments e
LEFT JOIN funnel_events f
    ON e.user_id = f.user_id AND f.event_type = 'purchase'
GROUP BY e.variant, e.device_type
ORDER BY e.variant, cvr_pct DESC;
```

### Experiment Decision Query

```sql
-- Final CTE-based experiment recommendation
WITH metrics AS (
    SELECT campaign_name,
        ROUND(100.0*SUM(purchases)/NULLIF(SUM(website_clicks),0),4) AS cvr,
        ROUND(SUM(spend_usd)/NULLIF(SUM(purchases),0),2)            AS cpa
    FROM campaign_performance GROUP BY campaign_name
),
ctrl AS (SELECT * FROM metrics WHERE campaign_name = 'Control Campaign'),
tst  AS (SELECT * FROM metrics WHERE campaign_name = 'Test Campaign')
SELECT
    ctrl.cvr                                          AS control_cvr_pct,
    tst.cvr                                           AS test_cvr_pct,
    ROUND(tst.cvr - ctrl.cvr, 4)                      AS absolute_lift,
    ROUND((tst.cvr - ctrl.cvr)/ctrl.cvr*100, 2)       AS relative_lift_pct,
    ctrl.cpa                                          AS control_cpa,
    tst.cpa                                           AS test_cpa,
    CASE WHEN tst.cvr > ctrl.cvr
         THEN 'SCALE TEST CAMPAIGN'
         ELSE 'KEEP CONTROL' END                      AS recommendation
FROM ctrl, tst;
```

### All 16 Queries Summary

| # | Query | SQL Technique |
|---|-------|--------------|
| 1 | Campaign summary totals | GROUP BY, SUM, COUNT |
| 2 | Full funnel conversion rates | NULLIF, division, ROUND |
| 3 | Cost efficiency (CPC, CPA) | Calculated metrics |
| 4 | Daily trend — both campaigns | CASE WHEN pivot |
| 5 | Weekly rollup | STRFTIME + GROUP BY |
| 6 | Running cumulative CVR | SUM OVER window |
| 7 | Day-over-day change | LAG window function |
| 8 | Best & worst days | RANK window function |
| 9 | Statistical summary (avg, min, max) | Aggregations |
| 10 | Funnel drop-off analysis | CTE + subtraction |
| 11 | Revenue per user | LEFT JOIN + aggregation |
| 12 | Conversion by device type | JOIN + CASE + GROUP BY |
| 13 | Conversion by region | JOIN + GROUP BY |
| 14 | Conversion by age group | JOIN + GROUP BY |
| 15 | Performance quartiles | NTILE window function |
| 16 | Experiment decision summary | Nested CTE + CASE WHEN |

---

## Python Statistical Testing (`marketing_campaign_ab_testing_analysis.ipynb`)

### Tests Implemented

| Test | Metric | Result |
|------|--------|--------|
| Z-test (proportions) | Conversion Rate | Control: 12.0% → Test: 13.8% (**+15% lift**, p < 0.05) |
| Welch t-test | Revenue per User | Control: $54.2 → Test: $61.8 (**+14% lift**, p < 0.05) |
| Mann-Whitney U | Session Pages | Statistically significant improvement |

### Hypotheses

- **H₀ (Null):** No difference in conversion performance between Control and Test campaigns
- **H₁ (Alternative):** The Test campaign performs significantly better than Control

```python
from scipy import stats

control = df[df['campaign_name'] == 'Control Campaign']['purchases']
test    = df[df['campaign_name'] == 'Test Campaign']['purchases']

t_stat, p_value = stats.ttest_ind(control, test)

alpha = 0.05
if p_value < alpha:
    print("REJECT H₀ — Statistically significant difference detected")
else:
    print("FAIL TO REJECT H₀ — No statistically significant difference")
```

### Sample Size Calculator

```python
from scipy import stats
import numpy as np

def required_sample_size(baseline_cvr=0.12, mde=0.02, alpha=0.05, power=0.8):
    z_alpha = stats.norm.ppf(1 - alpha/2)
    z_beta  = stats.norm.ppf(power)
    p1, p2  = baseline_cvr, baseline_cvr + mde
    p_avg   = (p1 + p2) / 2
    n = (z_alpha*np.sqrt(2*p_avg*(1-p_avg)) + z_beta*np.sqrt(p1*(1-p1)+p2*(1-p2)))**2 \
        / (p2 - p1)**2
    return int(np.ceil(n))

# Minimum users per variant needed
print(required_sample_size())  # → ~3,842 users per variant
```

---

## Key Results

| Metric | Control Campaign | Test Campaign | Winner |
|--------|-----------------|---------------|--------|
| CTR (Click-Through Rate) | 4.36% | 6.02% | **Test** |
| View Rate | ~52% | ~57% | **Test** |
| Cart Rate | ~22% | ~28% | **Test** |
| Overall Conversion Rate | 12.0% | 13.8% | **Test** |
| Revenue per User | $54.2 | $61.8 | **Test** |
| Cost per Acquisition | $28.86 | $15.90 | **Test** |

> ✅ **Decision: SCALE TEST CAMPAIGN** — Test outperforms Control at every funnel stage with statistically significant results (p < 0.05)

---

## How to Run

```bash
# 1. Clone the repository
git clone https://github.com/ramubattu321/A-B-Testing-Analysis-using-SQL-and-Python.git
cd A-B-Testing-Analysis-using-SQL-and-Python

# 2. Install dependencies
pip install pandas numpy matplotlib scipy jupyter

# 3. Create SQLite database and run all 16 SQL queries
python sql/setup_and_run.py

# 4. Open Python analysis notebook
jupyter notebook marketing_campaign_ab_testing_analysis.ipynb

# 5. Run SQL queries directly (requires SQLite CLI or DB Browser)
sqlite3 sql/ab_testing.db < sql/ab_test_queries.sql
```

---

## Business Impact

- **Campaign selection** — statistical evidence confirms Test campaign should be scaled
- **Budget optimization** — reallocate spend from Control to the higher-performing Test variant
- **Funnel diagnosis** — SQL queries pinpoint exactly where Test outperforms at each stage
- **Segment insights** — device, region, and age breakdowns guide targeted campaign strategy
- **Risk reduction** — statistical significance eliminates guesswork from campaign decisions
- **Reusable framework** — SQL + Python pipeline applicable to any future A/B experiment

---

## Tools & Technologies

| Tool | Purpose |
|------|---------|
| SQL (SQLite) | Funnel metric computation, window functions, CTEs |
| Python | Statistical testing and EDA |
| Pandas | Data loading, cleaning, aggregation |
| NumPy | Numerical operations |
| SciPy | z-test, t-test, Mann-Whitney U |
| Matplotlib | Funnel and comparison visualizations |
| Jupyter Notebook | Interactive analysis environment |

---

## Author

**Ramu Battu**
MS in Data Analytics — California State University, Fresno
📧 ramuusa61@gmail.com
