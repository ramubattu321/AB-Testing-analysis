-- ============================================================
-- A/B Testing Analysis — Production SQL Queries (15 Queries)
-- Marketing Campaign: Control vs Test Performance
-- Run in: SQLite / MySQL / PostgreSQL / AWS Athena
-- Author: Ramu Battu — MS Data Analytics, CSU Fresno
-- ============================================================


-- ── QUERY 1: CAMPAIGN SUMMARY — TOTAL METRICS ────────────────────────────────
-- Aggregate all funnel metrics by campaign for the full period
SELECT
    campaign_name,
    COUNT(DISTINCT campaign_date)               AS days_active,
    SUM(impressions)                            AS total_impressions,
    SUM(reach)                                  AS total_reach,
    SUM(website_clicks)                         AS total_clicks,
    SUM(searches)                               AS total_searches,
    SUM(content_views)                          AS total_views,
    SUM(add_to_cart)                            AS total_cart,
    SUM(purchases)                              AS total_purchases,
    ROUND(SUM(spend_usd), 2)                    AS total_spend_usd
FROM campaign_performance
GROUP BY campaign_name
ORDER BY campaign_name;


-- ── QUERY 2: FUNNEL CONVERSION RATES BY CAMPAIGN ─────────────────────────────
-- Compute conversion rate at every funnel stage
SELECT
    campaign_name,
    ROUND(100.0 * SUM(website_clicks)  / NULLIF(SUM(impressions),   0), 2) AS ctr_pct,
    ROUND(100.0 * SUM(searches)        / NULLIF(SUM(website_clicks), 0), 2) AS search_rate_pct,
    ROUND(100.0 * SUM(content_views)   / NULLIF(SUM(website_clicks), 0), 2) AS view_rate_pct,
    ROUND(100.0 * SUM(add_to_cart)     / NULLIF(SUM(content_views),  0), 2) AS cart_rate_pct,
    ROUND(100.0 * SUM(purchases)       / NULLIF(SUM(add_to_cart),    0), 2) AS checkout_rate_pct,
    ROUND(100.0 * SUM(purchases)       / NULLIF(SUM(website_clicks), 0), 2) AS overall_cvr_pct
FROM campaign_performance
GROUP BY campaign_name
ORDER BY campaign_name;


-- ── QUERY 3: COST EFFICIENCY METRICS ─────────────────────────────────────────
-- Cost per click, cost per view, cost per acquisition
SELECT
    campaign_name,
    ROUND(SUM(spend_usd) / NULLIF(SUM(website_clicks), 0), 2) AS cost_per_click,
    ROUND(SUM(spend_usd) / NULLIF(SUM(content_views),  0), 2) AS cost_per_view,
    ROUND(SUM(spend_usd) / NULLIF(SUM(add_to_cart),    0), 2) AS cost_per_cart,
    ROUND(SUM(spend_usd) / NULLIF(SUM(purchases),      0), 2) AS cost_per_acquisition,
    ROUND(SUM(spend_usd) / NULLIF(SUM(reach),          0), 4) AS spend_per_user
FROM campaign_performance
GROUP BY campaign_name
ORDER BY campaign_name;


-- ── QUERY 4: DAILY PERFORMANCE TREND — BOTH CAMPAIGNS ────────────────────────
-- Track daily metrics side by side for trend analysis
SELECT
    campaign_date,
    MAX(CASE WHEN campaign_name = 'Control Campaign'
        THEN ROUND(100.0 * website_clicks / NULLIF(impressions,0), 2) END) AS control_ctr,
    MAX(CASE WHEN campaign_name = 'Test Campaign'
        THEN ROUND(100.0 * website_clicks / NULLIF(impressions,0), 2) END) AS test_ctr,
    MAX(CASE WHEN campaign_name = 'Control Campaign'
        THEN ROUND(100.0 * purchases / NULLIF(website_clicks,0), 2) END)   AS control_cvr,
    MAX(CASE WHEN campaign_name = 'Test Campaign'
        THEN ROUND(100.0 * purchases / NULLIF(website_clicks,0), 2) END)   AS test_cvr,
    MAX(CASE WHEN campaign_name = 'Control Campaign'
        THEN purchases END)                                                 AS control_purchases,
    MAX(CASE WHEN campaign_name = 'Test Campaign'
        THEN purchases END)                                                 AS test_purchases
FROM campaign_performance
GROUP BY campaign_date
ORDER BY campaign_date;


-- ── QUERY 5: WEEKLY PERFORMANCE ROLLUP ───────────────────────────────────────
-- Aggregate metrics by week to smooth daily noise
SELECT
    campaign_name,
    STRFTIME('%Y-W%W', campaign_date)           AS week,
    SUM(impressions)                            AS weekly_impressions,
    SUM(website_clicks)                         AS weekly_clicks,
    SUM(purchases)                              AS weekly_purchases,
    ROUND(SUM(spend_usd), 2)                    AS weekly_spend,
    ROUND(100.0 * SUM(purchases)
          / NULLIF(SUM(website_clicks),0), 2)   AS weekly_cvr_pct
FROM campaign_performance
GROUP BY campaign_name, week
ORDER BY campaign_name, week;


-- ── QUERY 6: RUNNING CUMULATIVE METRICS (WINDOW FUNCTION) ────────────────────
-- Cumulative spend, clicks and purchases over time per campaign
SELECT
    campaign_name,
    campaign_date,
    purchases,
    website_clicks,
    spend_usd,
    SUM(purchases)      OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS cum_purchases,
    SUM(website_clicks) OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS cum_clicks,
    ROUND(SUM(spend_usd) OVER (PARTITION BY campaign_name ORDER BY campaign_date), 2) AS cum_spend,
    ROUND(100.0 *
          SUM(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) /
          NULLIF(SUM(website_clicks) OVER (PARTITION BY campaign_name ORDER BY campaign_date), 0),
          2)                                                                     AS running_cvr_pct
FROM campaign_performance
ORDER BY campaign_name, campaign_date;


-- ── QUERY 7: DAY-OVER-DAY CHANGE (LAG WINDOW FUNCTION) ───────────────────────
-- Track daily lift or drop vs previous day per campaign
SELECT
    campaign_name,
    campaign_date,
    purchases,
    LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS prev_day_purchases,
    purchases - LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS daily_change,
    ROUND(100.0 * (purchases - LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date))
          / NULLIF(LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date), 0), 1) AS dod_growth_pct
FROM campaign_performance
ORDER BY campaign_name, campaign_date;


-- ── QUERY 8: BEST AND WORST PERFORMING DAYS ──────────────────────────────────
-- Identify peak and low days per campaign using RANK
WITH ranked AS (
    SELECT
        campaign_name,
        campaign_date,
        purchases,
        website_clicks,
        ROUND(100.0 * purchases / NULLIF(website_clicks,0), 2) AS daily_cvr,
        RANK() OVER (PARTITION BY campaign_name ORDER BY purchases DESC) AS rank_best,
        RANK() OVER (PARTITION BY campaign_name ORDER BY purchases ASC)  AS rank_worst
    FROM campaign_performance
)
SELECT campaign_name, campaign_date, purchases, daily_cvr,
       CASE WHEN rank_best  <= 3 THEN 'Top 3 Day'
            WHEN rank_worst <= 3 THEN 'Bottom 3 Day'
            ELSE 'Normal' END AS day_classification
FROM ranked
WHERE rank_best <= 3 OR rank_worst <= 3
ORDER BY campaign_name, purchases DESC;


-- ── QUERY 9: STATISTICAL SUMMARY PER CAMPAIGN ────────────────────────────────
-- Avg, min, max, stddev of daily purchases for hypothesis testing context
SELECT
    campaign_name,
    COUNT(*)                                    AS days,
    ROUND(AVG(purchases), 1)                    AS avg_daily_purchases,
    MIN(purchases)                              AS min_purchases,
    MAX(purchases)                              AS max_purchases,
    ROUND(AVG(website_clicks), 0)               AS avg_daily_clicks,
    ROUND(AVG(spend_usd), 2)                    AS avg_daily_spend,
    ROUND(AVG(CAST(purchases AS REAL)
              / NULLIF(website_clicks,0)) * 100, 2) AS avg_daily_cvr_pct
FROM campaign_performance
GROUP BY campaign_name;


-- ── QUERY 10: FUNNEL DROP-OFF ANALYSIS ───────────────────────────────────────
-- Where are users dropping off most in the funnel?
WITH totals AS (
    SELECT
        campaign_name,
        SUM(impressions)    AS impressions,
        SUM(website_clicks) AS clicks,
        SUM(content_views)  AS views,
        SUM(add_to_cart)    AS cart,
        SUM(purchases)      AS purchases
    FROM campaign_performance
    GROUP BY campaign_name
)
SELECT
    campaign_name,
    impressions,
    clicks,
    views,
    cart,
    purchases,
    ROUND(100.0 * (impressions - clicks)  / impressions, 1) AS drop_imp_to_click_pct,
    ROUND(100.0 * (clicks - views)        / clicks,      1) AS drop_click_to_view_pct,
    ROUND(100.0 * (views - cart)          / views,       1) AS drop_view_to_cart_pct,
    ROUND(100.0 * (cart - purchases)      / cart,        1) AS drop_cart_to_purchase_pct
FROM totals
ORDER BY campaign_name;


-- ── QUERY 11: SEGMENT ANALYSIS BY DEVICE TYPE ────────────────────────────────
-- Compare conversion rates by device (mobile vs desktop vs tablet)
SELECT
    e.variant,
    e.device_type,
    COUNT(DISTINCT e.user_id)                   AS users,
    SUM(CASE WHEN f.event_type = 'purchase' THEN 1 ELSE 0 END) AS conversions,
    ROUND(100.0 * SUM(CASE WHEN f.event_type = 'purchase' THEN 1 ELSE 0 END)
          / COUNT(DISTINCT e.user_id), 2)       AS cvr_pct,
    ROUND(SUM(f.revenue), 2)                    AS total_revenue,
    ROUND(SUM(f.revenue)
          / NULLIF(COUNT(DISTINCT e.user_id),0), 2) AS revenue_per_user
FROM experiment_assignments e
LEFT JOIN funnel_events f
    ON e.user_id = f.user_id AND f.event_type = 'purchase'
GROUP BY e.variant, e.device_type
ORDER BY e.variant, cvr_pct DESC;


-- ── QUERY 12: SEGMENT ANALYSIS BY REGION ─────────────────────────────────────
-- Which regions respond better to the test campaign?
SELECT
    e.region,
    e.variant,
    COUNT(DISTINCT e.user_id)                   AS users,
    SUM(CASE WHEN f.event_type = 'purchase' THEN 1 ELSE 0 END) AS conversions,
    ROUND(100.0 * SUM(CASE WHEN f.event_type = 'purchase' THEN 1 ELSE 0 END)
          / COUNT(DISTINCT e.user_id), 2)       AS cvr_pct,
    ROUND(SUM(f.revenue), 2)                    AS total_revenue
FROM experiment_assignments e
LEFT JOIN funnel_events f
    ON e.user_id = f.user_id AND f.event_type = 'purchase'
GROUP BY e.region, e.variant
ORDER BY e.region, e.variant;


-- ── QUERY 13: AGE GROUP CONVERSION ANALYSIS ──────────────────────────────────
-- Which age groups convert best in each variant?
SELECT
    e.age_group,
    e.variant,
    COUNT(DISTINCT e.user_id)                   AS users,
    SUM(CASE WHEN f.event_type = 'purchase' THEN 1 ELSE 0 END) AS conversions,
    ROUND(100.0 * SUM(CASE WHEN f.event_type = 'purchase' THEN 1 ELSE 0 END)
          / COUNT(DISTINCT e.user_id), 2)       AS cvr_pct,
    ROUND(AVG(CASE WHEN f.event_type = 'purchase'
              THEN f.revenue END), 2)           AS avg_order_value
FROM experiment_assignments e
LEFT JOIN funnel_events f
    ON e.user_id = f.user_id AND f.event_type = 'purchase'
GROUP BY e.age_group, e.variant
ORDER BY e.age_group, e.variant;


-- ── QUERY 14: REVENUE PER USER — CONTROL VS TEST ─────────────────────────────
-- Core A/B test metric: revenue per user by variant
SELECT
    e.variant,
    COUNT(DISTINCT e.user_id)                   AS total_users,
    COUNT(DISTINCT CASE WHEN f.event_type = 'purchase'
                        THEN e.user_id END)     AS converting_users,
    ROUND(SUM(f.revenue), 2)                    AS total_revenue,
    ROUND(SUM(f.revenue)
          / NULLIF(COUNT(DISTINCT e.user_id),0), 2) AS revenue_per_user,
    ROUND(AVG(CASE WHEN f.event_type = 'purchase'
              THEN f.revenue END), 2)           AS avg_order_value,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN f.event_type = 'purchase'
                                      THEN e.user_id END)
          / COUNT(DISTINCT e.user_id), 2)       AS conversion_rate_pct
FROM experiment_assignments e
LEFT JOIN funnel_events f ON e.user_id = f.user_id
GROUP BY e.variant
ORDER BY e.variant;


-- ── QUERY 15: CAMPAIGN PERFORMANCE PERCENTILE RANKING (NTILE) ────────────────
-- Rank each day into performance quartiles using NTILE window function
SELECT
    campaign_name,
    campaign_date,
    purchases,
    website_clicks,
    ROUND(100.0 * purchases / NULLIF(website_clicks,0), 2)  AS daily_cvr,
    NTILE(4) OVER (PARTITION BY campaign_name
                   ORDER BY purchases)                       AS performance_quartile,
    CASE NTILE(4) OVER (PARTITION BY campaign_name ORDER BY purchases)
        WHEN 4 THEN 'Top 25% Day'
        WHEN 3 THEN 'Above Average'
        WHEN 2 THEN 'Below Average'
        WHEN 1 THEN 'Bottom 25% Day'
    END                                                      AS performance_label
FROM campaign_performance
ORDER BY campaign_name, campaign_date;


-- ── QUERY 16: EXPERIMENT DECISION SUMMARY ────────────────────────────────────
-- Final summary: lift calculation and recommendation
WITH metrics AS (
    SELECT
        campaign_name,
        ROUND(100.0 * SUM(purchases) / NULLIF(SUM(website_clicks),0), 4) AS cvr,
        ROUND(SUM(spend_usd) / NULLIF(SUM(purchases),0), 2)              AS cpa,
        SUM(purchases)                                                    AS total_conversions,
        ROUND(SUM(spend_usd), 2)                                          AS total_spend
    FROM campaign_performance
    GROUP BY campaign_name
),
control AS (SELECT * FROM metrics WHERE campaign_name = 'Control Campaign'),
test    AS (SELECT * FROM metrics WHERE campaign_name = 'Test Campaign')
SELECT
    'Experiment Decision Summary'                           AS report,
    control.cvr                                             AS control_cvr_pct,
    test.cvr                                                AS test_cvr_pct,
    ROUND(test.cvr - control.cvr, 4)                        AS absolute_lift_pct,
    ROUND((test.cvr - control.cvr) / control.cvr * 100, 2) AS relative_lift_pct,
    control.cpa                                             AS control_cpa_usd,
    test.cpa                                                AS test_cpa_usd,
    ROUND(control.cpa - test.cpa, 2)                        AS cpa_improvement_usd,
    CASE WHEN test.cvr > control.cvr
         THEN 'RECOMMEND TEST CAMPAIGN — Scale budget to Test variant'
         ELSE 'RECOMMEND CONTROL CAMPAIGN — Test did not outperform'
    END                                                     AS recommendation
FROM control, test;
