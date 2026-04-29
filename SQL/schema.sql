-- ============================================================
-- A/B Testing Analysis — Database Schema
-- Marketing Campaign Performance (Control vs Test)
-- Compatible with: SQLite, MySQL, PostgreSQL
-- ============================================================

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS campaign_performance;
DROP TABLE IF EXISTS experiment_assignments;
DROP TABLE IF EXISTS funnel_events;

-- ── TABLE 1: CAMPAIGN DAILY PERFORMANCE ──────────────────────────────────────
-- One row per campaign per day — all funnel metrics
CREATE TABLE campaign_performance (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    campaign_name    TEXT    NOT NULL,          -- 'Control Campaign' or 'Test Campaign'
    campaign_date    DATE    NOT NULL,           -- Date of performance data
    spend_usd        REAL    NOT NULL,           -- Ad spend in USD
    impressions      INTEGER NOT NULL,           -- Times ad was shown
    reach            INTEGER NOT NULL,           -- Unique users who saw the ad
    website_clicks   INTEGER NOT NULL,           -- Clicks to website
    searches         INTEGER NOT NULL,           -- Searches performed after click
    content_views    INTEGER NOT NULL,           -- Product pages viewed
    add_to_cart      INTEGER NOT NULL,           -- Items added to cart
    purchases        INTEGER NOT NULL            -- Completed transactions
);

-- ── TABLE 2: EXPERIMENT ASSIGNMENTS ──────────────────────────────────────────
-- User-level assignment to control or test variant
CREATE TABLE experiment_assignments (
    user_id          INTEGER PRIMARY KEY,
    variant          TEXT    NOT NULL,           -- 'control' or 'test'
    assigned_date    DATE    NOT NULL,
    device_type      TEXT,                       -- 'mobile', 'desktop', 'tablet'
    region           TEXT,                       -- 'North', 'South', 'East', 'West'
    age_group        TEXT                        -- '18-24', '25-34', '35-44', '45+'
);

-- ── TABLE 3: USER-LEVEL FUNNEL EVENTS ────────────────────────────────────────
-- Individual user actions across the funnel
CREATE TABLE funnel_events (
    event_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          INTEGER NOT NULL,
    event_type       TEXT    NOT NULL,           -- 'impression','click','view','cart','purchase'
    event_date       DATE    NOT NULL,
    revenue          REAL    DEFAULT 0,          -- Revenue if purchase event
    FOREIGN KEY (user_id) REFERENCES experiment_assignments(user_id)
);

-- ── INDEXES FOR PERFORMANCE ───────────────────────────────────────────────────
CREATE INDEX idx_campaign_name  ON campaign_performance(campaign_name);
CREATE INDEX idx_campaign_date  ON campaign_performance(campaign_date);
CREATE INDEX idx_variant        ON experiment_assignments(variant);
CREATE INDEX idx_device         ON experiment_assignments(device_type);
CREATE INDEX idx_region         ON experiment_assignments(region);
CREATE INDEX idx_event_type     ON funnel_events(event_type);
CREATE INDEX idx_event_user     ON funnel_events(user_id);
