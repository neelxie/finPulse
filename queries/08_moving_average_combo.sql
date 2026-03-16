-- ============================================================
-- Query: 3-month moving average with trend classification
-- File: queries/08_moving_average_combo.sql
-- ============================================================
--
-- Business question:
--   Monthly revenue is volatile — a single large deal or
--   late invoice can make a good month look bad or vice versa.
--   A 3-month moving average smooths this noise and reveals
--   the underlying trend. Is the business genuinely growing,
--   or is a strong month masking a declining baseline?
--   This is the standard technique used in FP&A reporting.
--
-- Approach:
--   Three CTEs, each adding one layer:
--     monthly_revenue — base aggregation (same as query 02)
--     with_moving_avg — applies AVG() OVER with ROWS BETWEEN
--                       2 PRECEDING AND CURRENT ROW, which
--                       averages the current month plus the
--                       two months before it (3 months total)
--     with_trend      — classifies each month's position
--                       relative to its own moving average
--                       and to the prior month's moving average
--                       (i.e. is the trend itself accelerating?)
--
--   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW is used rather
--   than RANGE because RANGE operates on values, not row
--   positions — if two months had the same revenue, RANGE
--   would include extra rows unpredictably.
--
--   The first two months will have a moving average based on
--   fewer than 3 data points (1 and 2 respectively). This is
--   correct PostgreSQL behaviour — it uses whatever rows are
--   available. It is flagged in the ma_basis column so
--   consumers of this query know which values are partial.
--
-- Tradeoff considered:
--   A 6-month or 12-month window would smooth more aggressively
--   but would also lag real trend changes by more. 3 months is
--   the standard finance default — responsive enough to catch
--   a turning point within a quarter, smooth enough to filter
--   single-month noise. The window size is isolated in the
--   ROWS clause for easy adjustment.
--
-- Expected output columns:
--   month, revenue, moving_avg_3m, ma_basis,
--   revenue_vs_ma, trend, ma_accelerating
-- ============================================================

WITH monthly_revenue AS (
  SELECT
    DATE_TRUNC('month', t.txn_date)::DATE  AS month,
    ROUND(SUM(t.amount), 2)                AS revenue
  FROM transactions t
  JOIN accounts a USING (account_id)
  WHERE a.account_type = 'revenue'
  GROUP BY 1
),

with_moving_avg AS (
  SELECT
    month,
    revenue,

    -- 3-month moving average (current + 2 prior months)
    ROUND(
      AVG(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
      )
    , 2)                                    AS moving_avg_3m,

    -- Track how many months contributed to this average
    -- (will be 1, 2, or 3 — important for first two rows)
    COUNT(*) OVER (
      ORDER BY month
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )                                       AS ma_basis,

    -- Prior month's moving average — used to assess if trend is accelerating
    LAG(
      ROUND(
        AVG(revenue) OVER (
          ORDER BY month
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )
      , 2)
    ) OVER (ORDER BY month)                 AS prev_moving_avg_3m

  FROM monthly_revenue
),

with_trend AS (
  SELECT
    month,
    revenue,
    moving_avg_3m,
    ma_basis,
    prev_moving_avg_3m,

    -- How far is current revenue above/below its own moving average?
    ROUND(revenue - moving_avg_3m, 2)       AS revenue_vs_ma,

    ROUND(
      (revenue - moving_avg_3m)
      / NULLIF(moving_avg_3m, 0) * 100
    , 1)                                    AS revenue_vs_ma_pct,

    -- Is revenue above or below its smoothed baseline?
    CASE
      WHEN revenue > moving_avg_3m  THEN 'above trend'
      WHEN revenue < moving_avg_3m  THEN 'below trend'
      ELSE 'on trend'
    END                                     AS trend,

    -- Is the moving average itself rising or falling?
    -- i.e. is the underlying business momentum improving?
    CASE
      WHEN prev_moving_avg_3m IS NULL               THEN 'baseline'
      WHEN moving_avg_3m > prev_moving_avg_3m       THEN 'accelerating'
      WHEN moving_avg_3m < prev_moving_avg_3m       THEN 'decelerating'
      ELSE 'stable'
    END                                     AS ma_momentum

  FROM with_moving_avg
)

SELECT
  month,
  revenue,
  moving_avg_3m,
  ma_basis                                  AS months_in_average,
  revenue_vs_ma,
  revenue_vs_ma_pct                         AS revenue_vs_ma_pct,
  trend,
  ma_momentum,

  -- Combined signal: is this month good AND is the trend improving?
  CASE
    WHEN trend = 'above trend' AND ma_momentum = 'accelerating'
      THEN 'strong — revenue up, trend improving'
    WHEN trend = 'above trend' AND ma_momentum = 'decelerating'
      THEN 'caution — revenue up but trend weakening'
    WHEN trend = 'below trend' AND ma_momentum = 'accelerating'
      THEN 'recovering — revenue soft but trend improving'
    WHEN trend = 'below trend' AND ma_momentum = 'decelerating'
      THEN 'concern — revenue down and trend worsening'
    ELSE 'neutral'
  END                                       AS combined_signal

FROM with_trend
ORDER BY month;