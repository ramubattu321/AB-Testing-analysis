-- ============================================
-- A/B Testing Analysis using SQL
-- Dataset columns assumed:
-- user_id, group_name, views, clicks, add_to_cart, purchases, revenue, device, region
-- ============================================

-- 1. Preview dataset
SELECT *
FROM ab_test
LIMIT 10;


-- 2. Total users by group
SELECT
    group_name,
    COUNT(*) AS total_users
FROM ab_test
GROUP BY group_name;


-- 3. Funnel metrics by group
SELECT
    group_name,
    COUNT(*) AS total_users,
    SUM(views) AS total_views,
    SUM(clicks) AS total_clicks,
    SUM(add_to_cart) AS total_carts,
    SUM(purchases) AS total_purchases,
    SUM(revenue) AS total_revenue,

    ROUND((SUM(clicks) * 100.0) / NULLIF(COUNT(*), 0), 2) AS ctr_percentage,
    ROUND((SUM(add_to_cart) * 100.0) / NULLIF(SUM(clicks), 0), 2) AS add_to_cart_rate,
    ROUND((SUM(purchases) * 100.0) / NULLIF(SUM(clicks), 0), 2) AS conversion_rate,
    ROUND(SUM(revenue) / NULLIF(COUNT(*), 0), 2) AS revenue_per_user
FROM ab_test
GROUP BY group_name;


-- 4. Conversion lift: test vs control
WITH conversion_summary AS (
    SELECT
        group_name,
        COUNT(*) AS total_users,
        SUM(purchases) AS total_purchases,
        (SUM(purchases) * 1.0 / COUNT(*)) AS conversion_rate
    FROM ab_test
    GROUP BY group_name
)
SELECT
    c.conversion_rate AS control_conversion_rate,
    t.conversion_rate AS test_conversion_rate,
    ROUND(((t.conversion_rate - c.conversion_rate) / NULLIF(c.conversion_rate, 0)) * 100, 2) AS conversion_lift_percentage
FROM conversion_summary c
JOIN conversion_summary t
    ON c.group_name = 'control'
   AND t.group_name = 'test';


-- 5. Revenue comparison by group
SELECT
    group_name,
    SUM(revenue) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_revenue_per_user,
    ROUND(SUM(revenue) / NULLIF(SUM(purchases), 0), 2) AS avg_order_value
FROM ab_test
GROUP BY group_name;


-- 6. Device-level performance by group
SELECT
    device,
    group_name,
    COUNT(*) AS total_users,
    SUM(clicks) AS total_clicks,
    SUM(add_to_cart) AS total_carts,
    SUM(purchases) AS total_purchases,
    SUM(revenue) AS total_revenue,
    ROUND((SUM(purchases) * 100.0) / NULLIF(COUNT(*), 0), 2) AS conversion_rate
FROM ab_test
GROUP BY device, group_name
ORDER BY device, group_name;


-- 7. Region-level performance by group
SELECT
    region,
    group_name,
    COUNT(*) AS total_users,
    SUM(clicks) AS total_clicks,
    SUM(add_to_cart) AS total_carts,
    SUM(purchases) AS total_purchases,
    SUM(revenue) AS total_revenue,
    ROUND((SUM(purchases) * 100.0) / NULLIF(COUNT(*), 0), 2) AS conversion_rate,
    ROUND(SUM(revenue) / NULLIF(COUNT(*), 0), 2) AS revenue_per_user
FROM ab_test
GROUP BY region, group_name
ORDER BY region, group_name;


-- 8. Click-to-purchase funnel by group
SELECT
    group_name,
    SUM(clicks) AS total_clicks,
    SUM(add_to_cart) AS total_add_to_cart,
    SUM(purchases) AS total_purchases,
    ROUND((SUM(add_to_cart) * 100.0) / NULLIF(SUM(clicks), 0), 2) AS click_to_cart_rate,
    ROUND((SUM(purchases) * 100.0) / NULLIF(SUM(add_to_cart), 0), 2) AS cart_to_purchase_rate
FROM ab_test
GROUP BY group_name;


-- 9. Best-performing segment by device and region
SELECT
    device,
    region,
    group_name,
    COUNT(*) AS total_users,
    SUM(purchases) AS total_purchases,
    SUM(revenue) AS total_revenue,
    ROUND((SUM(purchases) * 100.0) / NULLIF(COUNT(*), 0), 2) AS conversion_rate
FROM ab_test
GROUP BY device, region, group_name
ORDER BY conversion_rate DESC, total_revenue DESC;


-- 10. Final summary table for reporting
SELECT
    group_name,
    COUNT(*) AS total_users,
    SUM(clicks) AS total_clicks,
    SUM(add_to_cart) AS total_carts,
    SUM(purchases) AS total_purchases,
    SUM(revenue) AS total_revenue,
    ROUND((SUM(clicks) * 100.0) / NULLIF(COUNT(*), 0), 2) AS ctr_percentage,
    ROUND((SUM(add_to_cart) * 100.0) / NULLIF(SUM(clicks), 0), 2) AS add_to_cart_rate,
    ROUND((SUM(purchases) * 100.0) / NULLIF(SUM(clicks), 0), 2) AS conversion_rate,
    ROUND(SUM(revenue) / NULLIF(COUNT(*), 0), 2) AS revenue_per_user
FROM ab_test
GROUP BY group_name
ORDER BY group_name;
