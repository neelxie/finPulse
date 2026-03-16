-- ============================================================
-- Query: Monthly P&L — net profit per month via CTE chain
-- File: queries/06_cte_net_profit.sql
-- ============================================================
--
-- Business question:
--   What is the business's net profit (revenue minus expenses)
--   for each month? Are there months where we operated at a
--   loss? What is the profit margin trend over the year?
--   This is the core of a monthly management accounts report.
--
-- Approach:
--   Three CTEs chained sequentially — each does one job:
--     monthly_rev  — aggregate revenue by month
--     monthly_exp  — aggregate expenses by month
--     combined     — FULL OUTER JOIN to handle months that
--                    may appear in one set but not the other
--   The outer SELECT computes derived metrics (net_profit,
--   margin, running_profit_ytd) on the clean combined base.
--
--   FULL OUTER JOIN is deliberate: a LEFT JOIN would silently
--   drop expense-only months; FULL OUTER preserves all months
--   from both sides with COALESCE(..., 0) filling missing values.
--
--   A YTD running profit column is added using SUM() OVER
--   on the final result — demonstrating CTE + window function
--   composition in a single query.
--
-- Tradeoff considered:
--   Could be written as a single query with conditional
--   aggregation: SUM(CASE WHEN type='revenue' THEN amount END).
--   Rejected in favour of the CTE chain because: (1) it is
--   significantly more readable, (2) each CTE is independently
--   testable, and (3) it mirrors how this logic would be
--   structured in a dbt model or reporting pipeline.
--
-- Expected output columns:
--   month, revenue, expenses, net_profit,
--   profit_margin_pct, running_profit_ytd
-- ============================================================

WITH monthly_rev AS (
  SELECT
    DATE_TRUNC('month', t.txn_date)::DATE  AS month,
    ROUND(SUM(t.amount), 2)                AS revenue
  FROM transactions t
  JOIN accounts a USING (account_id)
  WHERE a.account_type = 'revenue'
  GROUP BY 1
),

monthly_exp AS (
  SELECT
    DATE_TRUNC('month', t.txn_date)::DATE  AS month,
    ROUND(SUM(t.amount), 2)                AS expenses
  FROM transactions t
  JOIN accounts a USING (account_id)
  WHERE a.account_type = 'expense'
  GROUP BY 1
),

combined AS (
  SELECT
    COALESCE(r.month, e.month)      AS month,
    COALESCE(r.revenue,  0)         AS revenue,
    COALESCE(e.expenses, 0)         AS expenses
  FROM monthly_rev r
  FULL OUTER JOIN monthly_exp e USING (month)
)

SELECT
  month,
  revenue,
  expenses,

  -- Net profit: positive = profitable month, negative = loss
  ROUND(revenue - expenses, 2)                          AS net_profit,

  -- Margin %: what proportion of revenue is kept as profit
  ROUND(
    (revenue - expenses) / NULLIF(revenue, 0) * 100
  , 1)                                                  AS profit_margin_pct,

  -- Year-to-date running profit — resets if data spans multiple years
  ROUND(
    SUM(revenue - expenses) OVER (
      PARTITION BY DATE_PART('year', month)
      ORDER BY month
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )
  , 2)                                                  AS running_profit_ytd,

  -- Profitability flag for dashboard conditional formatting
  CASE
    WHEN revenue - expenses > 0  THEN 'profitable'
    WHEN revenue - expenses < 0  THEN 'loss'
    ELSE 'break-even'
  END                                                   AS month_status

FROM combined
ORDER BY month;