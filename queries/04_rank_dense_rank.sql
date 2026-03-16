-- ============================================================
-- Query: Top expense accounts — RANK vs DENSE_RANK comparison
-- File: queries/04_rank_dense_rank.sql
-- ============================================================
--
-- Business question:
--   Which accounts are driving the most spending? Rank them
--   so management can identify the top cost centres and
--   prioritise budget review conversations.
--
-- Approach:
--   Aggregate total spend per account (expense accounts only),
--   then apply both RANK() and DENSE_RANK() in the same query
--   to show the difference explicitly.
--
--   RANK()       — skips position numbers after a tie.
--                  e.g. two accounts tied at #2 → next is #4.
--                  Use when the absolute position matters
--                  (e.g. "top 3 accounts" budget review).
--
--   DENSE_RANK() — never skips. Two tied at #2 → next is #3.
--                  Use when you want to know how many distinct
--                  tiers exist (e.g. "second-highest spend tier").
--
--   The rank_differs column flags rows where the two functions
--   produce different values — useful for surfacing ties to
--   reviewers who may not notice them in a dashboard.
--
-- Tradeoff considered:
--   ROW_NUMBER() was considered but rejected — it assigns a
--   unique rank even to tied values by breaking ties arbitrarily,
--   which would misrepresent accounts with equal spend as having
--   different priority levels. RANK/DENSE_RANK are both correct
--   here; which to use depends on downstream reporting logic.
--
-- Expected output columns:
--   account_name, total_spend, rank_result,
--   dense_rank_result, rank_differs
-- ============================================================

WITH expense_totals AS (
  SELECT
    a.account_id,
    a.account_name,
    ROUND(SUM(t.amount), 2)  AS total_spend
  FROM transactions t
  JOIN accounts a USING (account_id)
  WHERE a.account_type = 'expense'
  GROUP BY a.account_id, a.account_name
)
SELECT
  account_name,
  total_spend,

  RANK()       OVER (ORDER BY total_spend DESC)  AS rank_result,
  DENSE_RANK() OVER (ORDER BY total_spend DESC)  AS dense_rank_result,

  -- Highlight where the two functions diverge (i.e. there is a tie above this row)
  CASE
    WHEN RANK() OVER (ORDER BY total_spend DESC)
      <> DENSE_RANK() OVER (ORDER BY total_spend DESC)
    THEN 'YES — tie exists above'
    ELSE ''
  END                                             AS rank_differs

FROM expense_totals
ORDER BY total_spend DESC;