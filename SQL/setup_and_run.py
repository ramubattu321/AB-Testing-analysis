"""
A/B Testing Analysis — SQLite Database Setup & Query Runner
===========================================================
Creates a local SQLite database, loads sample data,
and runs all 16 SQL queries showing results.

Run: python sql/setup_and_run.py
"""

import sqlite3
import pandas as pd
import os

DB_PATH = "sql/ab_testing.db"
SQL_DIR = "sql"


def run_sql_file(conn, filepath):
    """Execute all statements in a SQL file."""
    with open(filepath, "r") as f:
        sql = f.read()
    # Split on semicolons but skip empty statements
    statements = [s.strip() for s in sql.split(";") if s.strip() and not s.strip().startswith("--")]
    cursor = conn.cursor()
    for stmt in statements:
        try:
            cursor.execute(stmt)
        except sqlite3.Error as e:
            print(f"  Warning: {e} — skipping statement")
    conn.commit()


def run_query(conn, query, title):
    """Run a single query and print results as a DataFrame."""
    print(f"\n{'='*65}")
    print(f"  {title}")
    print(f"{'='*65}")
    try:
        df = pd.read_sql_query(query, conn)
        print(df.to_string(index=False))
    except Exception as e:
        print(f"Error: {e}")
    return df


# ── MAIN ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":

    # Remove old DB if exists
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        print(f"Removed old database: {DB_PATH}")

    print("Creating SQLite database and loading data...")
    conn = sqlite3.connect(DB_PATH)

    # Run schema and data files
    run_sql_file(conn, os.path.join(SQL_DIR, "schema.sql"))
    print("✅ Schema created")

    run_sql_file(conn, os.path.join(SQL_DIR, "sample_data.sql"))
    print("✅ Sample data loaded")

    # Verify row counts
    cursor = conn.cursor()
    for table in ["campaign_performance", "experiment_assignments", "funnel_events"]:
        count = cursor.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"   {table}: {count:,} rows")

    print("\n" + "="*65)
    print("  RUNNING ALL 16 A/B TESTING SQL QUERIES")
    print("="*65)

    # ── QUERY 1 ───────────────────────────────────────────────────────────────
    run_query(conn, """
        SELECT campaign_name,
               COUNT(DISTINCT campaign_date) AS days_active,
               SUM(impressions)              AS total_impressions,
               SUM(website_clicks)           AS total_clicks,
               SUM(purchases)                AS total_purchases,
               ROUND(SUM(spend_usd),2)       AS total_spend_usd
        FROM campaign_performance
        GROUP BY campaign_name
    """, "QUERY 1 — Campaign Summary")

    # ── QUERY 2 ───────────────────────────────────────────────────────────────
    run_query(conn, """
        SELECT campaign_name,
               ROUND(100.0*SUM(website_clicks)/NULLIF(SUM(impressions),0),2)   AS ctr_pct,
               ROUND(100.0*SUM(content_views)/NULLIF(SUM(website_clicks),0),2) AS view_rate_pct,
               ROUND(100.0*SUM(add_to_cart)/NULLIF(SUM(content_views),0),2)    AS cart_rate_pct,
               ROUND(100.0*SUM(purchases)/NULLIF(SUM(website_clicks),0),2)     AS overall_cvr_pct
        FROM campaign_performance
        GROUP BY campaign_name
    """, "QUERY 2 — Funnel Conversion Rates")

    # ── QUERY 3 ───────────────────────────────────────────────────────────────
    run_query(conn, """
        SELECT campaign_name,
               ROUND(SUM(spend_usd)/NULLIF(SUM(website_clicks),0),2) AS cost_per_click,
               ROUND(SUM(spend_usd)/NULLIF(SUM(add_to_cart),0),2)    AS cost_per_cart,
               ROUND(SUM(spend_usd)/NULLIF(SUM(purchases),0),2)      AS cost_per_acquisition
        FROM campaign_performance
        GROUP BY campaign_name
    """, "QUERY 3 — Cost Efficiency (CPC, CPCart, CPA)")

    # ── QUERY 4 ───────────────────────────────────────────────────────────────
    run_query(conn, """
        SELECT campaign_date,
               MAX(CASE WHEN campaign_name='Control Campaign'
                   THEN ROUND(100.0*purchases/NULLIF(website_clicks,0),2) END) AS control_cvr,
               MAX(CASE WHEN campaign_name='Test Campaign'
                   THEN ROUND(100.0*purchases/NULLIF(website_clicks,0),2) END) AS test_cvr,
               MAX(CASE WHEN campaign_name='Control Campaign' THEN purchases END) AS control_purch,
               MAX(CASE WHEN campaign_name='Test Campaign'    THEN purchases END) AS test_purch
        FROM campaign_performance
        GROUP BY campaign_date
        ORDER BY campaign_date
        LIMIT 10
    """, "QUERY 4 — Daily Trend (first 10 days)")

    # ── QUERY 5: Running CVR ──────────────────────────────────────────────────
    run_query(conn, """
        SELECT campaign_name, campaign_date, purchases,
               SUM(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS cum_purchases,
               ROUND(100.0 *
                     SUM(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) /
                     NULLIF(SUM(website_clicks) OVER (PARTITION BY campaign_name ORDER BY campaign_date),0),
                     2) AS running_cvr_pct
        FROM campaign_performance
        ORDER BY campaign_name, campaign_date
        LIMIT 14
    """, "QUERY 5 — Cumulative Running CVR (Window Function)")

    # ── QUERY 6: DoD Change ───────────────────────────────────────────────────
    run_query(conn, """
        SELECT campaign_name, campaign_date, purchases,
               LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS prev_day,
               purchases - LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date) AS change,
               ROUND(100.0*(purchases - LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date))
                     /NULLIF(LAG(purchases) OVER (PARTITION BY campaign_name ORDER BY campaign_date),0),1) AS dod_pct
        FROM campaign_performance
        ORDER BY campaign_name, campaign_date
        LIMIT 14
    """, "QUERY 6 — Day-over-Day Change (LAG Window Function)")

    # ── QUERY 7: Best/Worst days ──────────────────────────────────────────────
    run_query(conn, """
        WITH ranked AS (
            SELECT campaign_name, campaign_date, purchases,
                   RANK() OVER (PARTITION BY campaign_name ORDER BY purchases DESC) AS rank_best,
                   RANK() OVER (PARTITION BY campaign_name ORDER BY purchases ASC)  AS rank_worst
            FROM campaign_performance
        )
        SELECT campaign_name, campaign_date, purchases,
               CASE WHEN rank_best<=3  THEN 'Top 3 Day'
                    WHEN rank_worst<=3 THEN 'Bottom 3 Day' END AS label
        FROM ranked WHERE rank_best<=3 OR rank_worst<=3
        ORDER BY campaign_name, purchases DESC
    """, "QUERY 7 — Best & Worst Days (RANK Window Function)")

    # ── QUERY 8: Statistical Summary ─────────────────────────────────────────
    run_query(conn, """
        SELECT campaign_name,
               ROUND(AVG(purchases),1)      AS avg_daily_purchases,
               MIN(purchases)               AS min_purchases,
               MAX(purchases)               AS max_purchases,
               ROUND(AVG(spend_usd),2)      AS avg_daily_spend,
               ROUND(AVG(CAST(purchases AS REAL)/NULLIF(website_clicks,0))*100,2) AS avg_cvr_pct
        FROM campaign_performance
        GROUP BY campaign_name
    """, "QUERY 8 — Statistical Summary")

    # ── QUERY 9: Funnel Drop-off ──────────────────────────────────────────────
    run_query(conn, """
        WITH t AS (
            SELECT campaign_name,
                   SUM(impressions) AS imp, SUM(website_clicks) AS clk,
                   SUM(content_views) AS vw, SUM(add_to_cart) AS cart, SUM(purchases) AS purch
            FROM campaign_performance GROUP BY campaign_name
        )
        SELECT campaign_name,
               ROUND(100.0*(imp-clk)/imp,1)   AS drop_imp_click_pct,
               ROUND(100.0*(clk-vw)/clk,1)    AS drop_click_view_pct,
               ROUND(100.0*(vw-cart)/vw,1)    AS drop_view_cart_pct,
               ROUND(100.0*(cart-purch)/cart,1)AS drop_cart_purch_pct
        FROM t ORDER BY campaign_name
    """, "QUERY 9 — Funnel Drop-off Analysis")

    # ── QUERY 10: Revenue per User ────────────────────────────────────────────
    run_query(conn, """
        SELECT e.variant,
               COUNT(DISTINCT e.user_id) AS total_users,
               COUNT(DISTINCT CASE WHEN f.event_type='purchase' THEN e.user_id END) AS converters,
               ROUND(SUM(f.revenue),2)   AS total_revenue,
               ROUND(SUM(f.revenue)/NULLIF(COUNT(DISTINCT e.user_id),0),2) AS revenue_per_user,
               ROUND(100.0*COUNT(DISTINCT CASE WHEN f.event_type='purchase' THEN e.user_id END)
                     /COUNT(DISTINCT e.user_id),2) AS cvr_pct
        FROM experiment_assignments e
        LEFT JOIN funnel_events f ON e.user_id=f.user_id
        GROUP BY e.variant ORDER BY e.variant
    """, "QUERY 10 — Revenue per User (Control vs Test)")

    # ── QUERY 11: Device Segment ──────────────────────────────────────────────
    run_query(conn, """
        SELECT e.variant, e.device_type,
               COUNT(DISTINCT e.user_id) AS users,
               SUM(CASE WHEN f.event_type='purchase' THEN 1 ELSE 0 END) AS conversions,
               ROUND(100.0*SUM(CASE WHEN f.event_type='purchase' THEN 1 ELSE 0 END)
                     /COUNT(DISTINCT e.user_id),2) AS cvr_pct,
               ROUND(SUM(f.revenue),2) AS total_revenue
        FROM experiment_assignments e
        LEFT JOIN funnel_events f ON e.user_id=f.user_id AND f.event_type='purchase'
        GROUP BY e.variant, e.device_type
        ORDER BY e.variant, cvr_pct DESC
    """, "QUERY 11 — Conversion by Device Type")

    # ── QUERY 12: Region Segment ──────────────────────────────────────────────
    run_query(conn, """
        SELECT e.region, e.variant,
               COUNT(DISTINCT e.user_id) AS users,
               SUM(CASE WHEN f.event_type='purchase' THEN 1 ELSE 0 END) AS conversions,
               ROUND(100.0*SUM(CASE WHEN f.event_type='purchase' THEN 1 ELSE 0 END)
                     /COUNT(DISTINCT e.user_id),2) AS cvr_pct
        FROM experiment_assignments e
        LEFT JOIN funnel_events f ON e.user_id=f.user_id AND f.event_type='purchase'
        GROUP BY e.region, e.variant
        ORDER BY e.region, e.variant
    """, "QUERY 12 — Conversion by Region")

    # ── QUERY 13: Age Group ───────────────────────────────────────────────────
    run_query(conn, """
        SELECT e.age_group, e.variant,
               COUNT(DISTINCT e.user_id) AS users,
               SUM(CASE WHEN f.event_type='purchase' THEN 1 ELSE 0 END) AS conversions,
               ROUND(100.0*SUM(CASE WHEN f.event_type='purchase' THEN 1 ELSE 0 END)
                     /COUNT(DISTINCT e.user_id),2) AS cvr_pct
        FROM experiment_assignments e
        LEFT JOIN funnel_events f ON e.user_id=f.user_id AND f.event_type='purchase'
        GROUP BY e.age_group, e.variant
        ORDER BY e.age_group, e.variant
    """, "QUERY 13 — Conversion by Age Group")

    # ── QUERY 14: NTILE Quartile Ranking ─────────────────────────────────────
    run_query(conn, """
        SELECT campaign_name, campaign_date, purchases,
               NTILE(4) OVER (PARTITION BY campaign_name ORDER BY purchases) AS quartile,
               CASE NTILE(4) OVER (PARTITION BY campaign_name ORDER BY purchases)
                   WHEN 4 THEN 'Top 25%' WHEN 3 THEN 'Above Avg'
                   WHEN 2 THEN 'Below Avg' WHEN 1 THEN 'Bottom 25%' END AS label
        FROM campaign_performance
        ORDER BY campaign_name, campaign_date
        LIMIT 14
    """, "QUERY 14 — Performance Quartiles (NTILE Window Function)")

    # ── QUERY 15: Weekly Rollup ───────────────────────────────────────────────
    run_query(conn, """
        SELECT campaign_name,
               STRFTIME('%Y-W%W', campaign_date) AS week,
               SUM(purchases) AS weekly_purchases,
               ROUND(SUM(spend_usd),2) AS weekly_spend,
               ROUND(100.0*SUM(purchases)/NULLIF(SUM(website_clicks),0),2) AS weekly_cvr_pct
        FROM campaign_performance
        GROUP BY campaign_name, week
        ORDER BY campaign_name, week
    """, "QUERY 15 — Weekly Performance Rollup")

    # ── QUERY 16: Final Decision ──────────────────────────────────────────────
    run_query(conn, """
        WITH m AS (
            SELECT campaign_name,
                   ROUND(100.0*SUM(purchases)/NULLIF(SUM(website_clicks),0),4) AS cvr,
                   ROUND(SUM(spend_usd)/NULLIF(SUM(purchases),0),2) AS cpa
            FROM campaign_performance GROUP BY campaign_name
        ),
        ctrl AS (SELECT * FROM m WHERE campaign_name='Control Campaign'),
        tst  AS (SELECT * FROM m WHERE campaign_name='Test Campaign')
        SELECT ctrl.cvr AS control_cvr, tst.cvr AS test_cvr,
               ROUND(tst.cvr-ctrl.cvr,4) AS absolute_lift,
               ROUND((tst.cvr-ctrl.cvr)/ctrl.cvr*100,2) AS relative_lift_pct,
               ctrl.cpa AS control_cpa, tst.cpa AS test_cpa,
               CASE WHEN tst.cvr>ctrl.cvr THEN 'SCALE TEST CAMPAIGN' ELSE 'KEEP CONTROL' END AS recommendation
        FROM ctrl, tst
    """, "QUERY 16 — Experiment Decision & Recommendation")

    conn.close()
    print(f"\n{'='*65}")
    print(f"✅ All 16 queries complete! Database saved: {DB_PATH}")
    print(f"{'='*65}")
