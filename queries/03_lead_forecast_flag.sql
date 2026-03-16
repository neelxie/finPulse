-- ============================================================
-- Query: Next-month revenue forecast risk flag
-- File: queries/03_lead_forecast_flag.sql
-- ============================================================
--
-- Business question:
--   Based on current revenue trajectory, which months are
--   "at risk" of a significant drop next month (>20% decline)?
--   Finance teams use this to trigger early interventions —
--   sales pushes, cost freezes, or cash reserve draws —
--   before a shortfall is confirmed.
--
-- Approach:
--   LEAD(revenue, 1) looks one row forward in the ordered
--   result set, giving us the next month's revenue from the
--   perspective of each current row.
--   The forecast_flag CASE expression classifies each month:
--     - 'at risk'  : next month projected >20% below current
--     - 'stable'   : next month within 20% of current
--     - 'no data'  : last month in dataset (no future row)
--   A second flag, trend_direction, captures the raw direction
--   for charting purposes independently of the threshold.
--
-- Tradeoff considered:
--   The 20% threshold is a business parameter, not a SQL
--   constant — in production this would be a config value or
--   passed as a parameterised query argument. Hard-coding it
--   here for clarity, but it is isolated in one CASE expression
--   for easy modification.
--
-- Expected output columns:
--   month, revenue, next_month_revenue,
--   revenue_delta, forecast_flag, trend_direction
-- ============================================================

WITH monthly_revenue AS (
  SELECT
    DATE_TRUNC('month', t.txn_date)::DATE  AS month,
    SUM(t.amount)                           AS revenue
  FROM transactions t
  JOIN accounts a USING (account_id)
  WHERE a.account_type = 'revenue'
  GROUP BY 1
),
with_lead AS (
  SELECT
    month,
    revenue,
    LEAD(revenue, 1) OVER (ORDER BY month)  AS next_month_revenue
  FROM monthly_revenue
)
SELECT
  month,
  revenue,
  next_month_revenue,

  -- Raw delta to next month
  ROUND(next_month_revenue - revenue, 2)    AS revenue_delta,

  -- Risk classification using the 20% threshold
  CASE
    WHEN next_month_revenue IS NULL
      THEN 'no data'
    WHEN (revenue - next_month_revenue) / NULLIF(revenue, 0) > 0.20
      THEN 'at risk'
    ELSE 'stable'
  END                                        AS forecast_flag,

  -- Simple direction for charting (independent of threshold)
  CASE
    WHEN next_month_revenue IS NULL  THEN 'unknown'
    WHEN next_month_revenue > revenue THEN 'up'
    WHEN next_month_revenue < revenue THEN 'down'
    ELSE 'flat'
  END                                        AS trend_direction

FROM with_lead
ORDER BY month;