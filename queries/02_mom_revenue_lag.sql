-- ============================================================
-- Query: Month-over-month revenue change
-- File: queries/02_mom_revenue_lag.sql
-- ============================================================
--
-- Business question:
--   How is revenue trending month by month? Which months
--   showed a decline, by how much, and is the business
--   accelerating or decelerating over time?
--   This is the foundational metric in any finance dashboard.
--
-- Approach:
--   Step 1 — aggregate raw transactions to monthly revenue
--   using DATE_TRUNC('month') inside a CTE. This isolates
--   the aggregation logic cleanly before the window layer.
--   Step 2 — apply LAG(revenue, 1) in the outer query to
--   compare each month to the one immediately before it.
--   NULLIF on the LAG value prevents division-by-zero if a
--   prior month had zero revenue (e.g. first month of data).
--
-- Tradeoff considered:
--   Alternative: self-join the CTE on month - interval '1 month'.
--   Rejected because LAG is cleaner, avoids an extra JOIN, and
--   correctly handles gaps in months (where a self-join on exact
--   date arithmetic would return NULL silently without warning).
--   LAG makes the intent explicit and readable.
--
-- Expected output columns:
--   month, revenue, prev_month_revenue, abs_change, pct_change
-- ============================================================

WITH monthly_revenue AS (
  SELECT
    DATE_TRUNC('month', t.txn_date)::DATE  AS month,
    SUM(t.amount)                           AS revenue
  FROM transactions t
  JOIN accounts a USING (account_id)
  WHERE a.account_type = 'revenue'
  GROUP BY 1
)
SELECT
  month,
  revenue,
  LAG(revenue, 1) OVER (ORDER BY month)                             AS prev_month_revenue,

  -- Absolute change: positive = growth, negative = decline
  revenue - LAG(revenue, 1) OVER (ORDER BY month)                   AS abs_change,

  -- Percentage change: NULLIF guards against division by zero on first row
  ROUND(
    (revenue - LAG(revenue, 1) OVER (ORDER BY month))
    / NULLIF(LAG(revenue, 1) OVER (ORDER BY month), 0) * 100
  , 1)                                                               AS pct_change

FROM monthly_revenue
ORDER BY month;