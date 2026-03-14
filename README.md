# A/B Testing Analysis for Marketing Campaign Performance

## Project Overview

This project analyzes the performance of two marketing campaigns using **A/B testing** to determine which campaign performs better in terms of user engagement and conversions.

The analysis compares a **control group** and a **test group** based on several marketing and user behavior metrics such as impressions, clicks, searches, content views, add-to-cart actions, and purchases.

The goal is to understand which campaign drives higher engagement and leads to more purchases.

---

## Dataset Features

The dataset contains the following variables:

1. **Campaign Name** – Name of the marketing campaign
2. **Date** – Date of the campaign record
3. **Spend** – Amount spent on the campaign (USD)
4. **# of Impressions** – Total number of ad impressions
5. **Reach** – Number of unique users who saw the ad
6. **# of Website Clicks** – Number of clicks on the website from ads
7. **# of Searches** – Number of users who performed searches on the website
8. **# of View Content** – Number of users who viewed product content
9. **# of Add to Cart** – Number of users who added products to their cart
10. **# of Purchase** – Number of purchases made

---

## Dataset Files

Control and test campaign datasets used for the analysis:

* **control_group.csv**
* **test_group.csv**

These datasets represent the two campaign variations used in the A/B testing experiment.

---

## Exploratory Data Analysis (EDA)

The following steps were performed during data exploration:

* Importing required Python libraries
* Checking for missing (NULL) values
* Handling missing values using mean imputation
* Merging control and test datasets
* Verifying equal sample sizes
* Preparing the dataset for comparison and analysis

---

## A/B Testing Analysis

The following metrics were analyzed to compare campaign performance:

* Total impressions for each campaign
* Number of searches performed on the website
* Website clicks from each campaign
* Content viewed after website visits
* Number of products added to cart
* Total campaign spending
* Number of purchases generated
* Relationship between:

  * Website clicks vs content views
  * Content views vs add-to-cart actions
  * Add-to-cart actions vs purchases

---

## Tools & Technologies

* Python
* Pandas
* NumPy
* Matplotlib
* Jupyter Notebook

---

## Project Structure

A-B-Test
│
├── control_group.csv
├── test_group.csv
├── ab_testing_analysis.ipynb
└── README.md

---

## Author

Ramu Battu
Graduate Student – California State University, Fresno
GitHub: https://github.com/ramubattu321
