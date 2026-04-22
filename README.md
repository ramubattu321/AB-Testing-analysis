# A/B Testing Analysis using SQL and Python

## Overview
This project analyzes the performance of two marketing campaigns using **A/B testing** to determine which campaign performs better in terms of user engagement and conversions.

The analysis compares a **control group** and a **test group** across multiple funnel metrics to support data-driven marketing decisions.

---

## Business Problem
Organizations run A/B tests to evaluate campaign effectiveness. This project aims to:

- Identify which campaign generates higher engagement  
- Compare conversion performance across user actions  
- Support decision-making for marketing optimization  

---

## Dataset
The dataset contains campaign performance metrics including:

- Campaign Name  
- Date  
- Spend (USD)  
- Impressions  
- Reach  
- Website Clicks  
- Searches  
- Content Views  
- Add-to-Cart Actions  
- Purchases  

### Dataset Files
- `control_group.csv`  
- `test_group.csv`  

---

## Methodology

### Data Processing
- Cleaned and merged control and test datasets  
- Handled missing values using mean imputation  
- Verified consistency and sample sizes  

---

### Exploratory Data Analysis (EDA)
- Analyzed user behavior across funnel stages  
- Compared engagement metrics between campaigns  
- Identified relationships between user actions  

---

### Statistical Testing
- Conducted hypothesis testing to compare campaign performance  
- Null Hypothesis (H₀): No difference between campaigns  
- Alternative Hypothesis (H₁): Test campaign performs better  
- Evaluated results using statistical significance (p-value approach, α = 0.05)  

---

### SQL Analysis
- Performed funnel analysis using SQL queries  
- Calculated key metrics such as:
  - Click-Through Rate (CTR)  
  - Add-to-Cart Rate  
  - Conversion Rate  
  - Cost per Purchase  
- Compared control and test group performance at the database level  

---

## Key Metrics
- Impressions  
- Website Clicks  
- Add-to-Cart Actions  
- Purchases  
- Conversion Rate  
- Cost Efficiency  

---

## Key Insights
- Identified differences in user engagement between campaigns  
- Analyzed conversion behavior across funnel stages  
- Highlighted which campaign performs better in driving purchases  

---

## Business Impact
- Supports data-driven marketing decisions  
- Helps optimize campaign performance and budget allocation  
- Reduces risk of ineffective marketing strategies  
- Improves conversion and revenue outcomes  

---

## Tools & Technologies
- Python  
- Pandas  
- NumPy  
- Matplotlib  
- SQL  
- Jupyter Notebook  

---

## Project Structure
A-B-Test
│
├── data/
│   ├── control_group.csv
│   ├── test_group.csv
│
├── sql/
│   └── ab_test_queries.sql
│
├── notebooks/
│   └── marketing_campaign_ab_testing_analysis.ipynb
│
├── README.md

---

## Applications
- Marketing campaign optimization  
- Conversion rate analysis  
- Customer behavior analysis  
- Product feature experimentation  

---

## Author
Ramu Battu  
MS Data Analytics – California State University, Fresno  
