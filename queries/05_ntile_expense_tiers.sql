-- ============================================================
-- Query: Expense transaction quartile tiers (NTILE)
-- File: queries/05_ntile_expense_tiers.sql
-- ============================================================
--
-- Business question:
--   Which individual expense transactions are routine vs
--   outliers? Finance teams use quartile segmentation to
--   decide which transactions need approval, review, or
--   audit — and which can be auto-processed.
--
-- Approach:
--   NTILE(4) divides all expense transactions into 4 equally-
--   sized buckets ordered by amount ascending:
--     Q1 (lowest 25%)  → routine spend, auto-approve
--     Q2 (25–50%)      → moderate, standard review
--     Q3 (50–75%)      → significant, manager sign-off
--     Q4 (highest 25%) → outlier, finance director review
--
--   A summary CTE is included to show the min/max/avg per
--   quartile — this turns the query into a self-documenting
--   audit report rather than just a labelled list.
--
-- Tradeoff considered:
--   NTILE does not guarantee equal bucket sizes when the row
--   count is not divisible by N — it distributes the remainder
--   into the earlier buckets. This is documented PostgreSQL
--   behaviour and is acceptable for spend tiering. For exact
--   percentile boundaries, PERCENTILE_CONT (an ordered-set
--   aggregate) would be more precise but less readable here.
--
-- Expected output columns:
--   txn_id, txn_date, account_name, description,
--   amount, quartile, spend_tier, approval_action
-- ============================================================

WITH bucketed AS (
  SELECT
    t.txn_id,
    t.txn_date,
    a.account_name,
    t.description,
    t.amount,
    NTILE(4) OVER (ORDER BY t.amount ASC)  AS quartile
  FROM transactions t
  JOIN accounts a USING (account_id)
  WHERE a.account_type = 'expense'
),
quartile_summary AS (
  -- Descriptive stats per tier — append to results for auditability
  SELECT
    quartile,
    COUNT(*)                    AS txn_count,
    ROUND(MIN(amount), 2)       AS tier_min,
    ROUND(MAX(amount), 2)       AS tier_max,
    ROUND(AVG(amount), 2)       AS tier_avg
  FROM bucketed
  GROUP BY quartile
)
SELECT
  b.txn_id,
  b.txn_date,
  b.account_name,
  b.description,
  b.amount,
  b.quartile,

  CASE b.quartile
    WHEN 1 THEN 'routine'
    WHEN 2 THEN 'moderate'
    WHEN 3 THEN 'significant'
    WHEN 4 THEN 'outlier'
  END                           AS spend_tier,

  CASE b.quartile
    WHEN 1 THEN 'auto-approve'
    WHEN 2 THEN 'standard review'
    WHEN 3 THEN 'manager sign-off'
    WHEN 4 THEN 'director review'
  END                           AS approval_action,

  -- Include tier boundary info on every row for context
  qs.tier_min,
  qs.tier_max,
  qs.tier_avg

FROM bucketed b
JOIN quartile_summary qs USING (quartile)
ORDER BY b.quartile DESC, b.amount DESC;