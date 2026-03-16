-- ============================================================
-- Query: Month-over-month revenue change
-- File: queries/02_mom_revenue_lag.sql
-- ============================================================
--
-- Business question:
--   How is revenue trending month by month?
--   Which months showed decline and by how much?
--
-- Approach:
--   Aggregate revenue by month with DATE_TRUNC, then apply
--   LAG() window function to compare each month to the prior.
--   NULLIF on the denominator prevents division-by-zero on
--   the first month row.
--
-- Tradeoff considered:
--   Could use a self-join on the aggregated CTE instead of LAG,
--   but LAG is cleaner, more readable, and avoids the extra join.
--
-- Expected output columns:
--   month, revenue, prev_revenue, pct_change
-- ============================================================

WITH monthly AS (
  SELECT
    DATE_TRUNC('month', t.txn_date) AS month,
    SUM(t.amount)                   AS revenue
  FROM transactions t
  JOIN accounts a USING (account_id)
  WHERE a.account_type = 'revenue'
  GROUP BY 1
)
SELECT
  month,
  revenue,
  LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
  ROUND(
    (revenue - LAG(revenue) OVER (ORDER BY month))
    / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100
  , 1) AS pct_change
FROM monthly
ORDER BY month;