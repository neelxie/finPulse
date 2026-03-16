-- ============================================================
-- FinPulse Analytics — Seed Data
-- File: schema/02_seed_data.sql
-- Description: Realistic 2024 financial dataset
--              6 accounts, 72 transactions across 12 months
-- ============================================================

\c finpulse

-- ============================================================
-- Accounts
-- ============================================================
INSERT INTO accounts (account_id, account_name, account_type, parent_account_id) VALUES
  (1, 'Product Sales',       'revenue', NULL),
  (2, 'Consulting Revenue',  'revenue', NULL),
  (3, 'Rent',                'expense', 6),
  (4, 'Salaries',            'expense', 6),
  (5, 'Utilities',           'expense', 6),
  (6, 'Operating Expenses',  'expense', NULL),
  (7, 'Cash Reserve',        'asset',   NULL);

-- ============================================================
-- Transactions — 2024, 12 months, realistic variance
-- ============================================================
INSERT INTO transactions (account_id, txn_date, amount, category, description) VALUES
-- January
  (1, '2024-01-05',  9200.00, 'sales',       'Jan product sales batch 1'),
  (1, '2024-01-18',  3400.00, 'sales',       'Jan product sales batch 2'),
  (2, '2024-01-22',  4800.00, 'consulting',  'Consulting retainer — Client A'),
  (4, '2024-01-31',  5500.00, 'payroll',     'Jan salaries'),
  (3, '2024-01-31',  2200.00, 'facilities',  'Jan rent'),
  (5, '2024-01-31',   310.00, 'utilities',   'Jan utilities'),
-- February
  (1, '2024-02-07',  7800.00, 'sales',       'Feb product sales batch 1'),
  (1, '2024-02-20',  2100.00, 'sales',       'Feb product sales batch 2'),
  (2, '2024-02-25',  4800.00, 'consulting',  'Consulting retainer — Client A'),
  (4, '2024-02-29',  5500.00, 'payroll',     'Feb salaries'),
  (3, '2024-02-29',  2200.00, 'facilities',  'Feb rent'),
  (5, '2024-02-29',   290.00, 'utilities',   'Feb utilities'),
-- March
  (1, '2024-03-04', 11400.00, 'sales',       'Mar product sales batch 1'),
  (1, '2024-03-19',  3900.00, 'sales',       'Mar product sales batch 2'),
  (2, '2024-03-28',  6200.00, 'consulting',  'Consulting retainer — Client B (new)'),
  (4, '2024-03-31',  5500.00, 'payroll',     'Mar salaries'),
  (3, '2024-03-31',  2200.00, 'facilities',  'Mar rent'),
  (5, '2024-03-31',   340.00, 'utilities',   'Mar utilities'),
-- April
  (1, '2024-04-08',  8700.00, 'sales',       'Apr product sales batch 1'),
  (2, '2024-04-15',  6200.00, 'consulting',  'Consulting retainer — Client B'),
  (2, '2024-04-22',  2500.00, 'consulting',  'Ad hoc consulting — Client C'),
  (4, '2024-04-30',  5800.00, 'payroll',     'Apr salaries (increment)'),
  (3, '2024-04-30',  2200.00, 'facilities',  'Apr rent'),
  (5, '2024-04-30',   275.00, 'utilities',   'Apr utilities'),
-- May
  (1, '2024-05-06', 10100.00, 'sales',       'May product sales batch 1'),
  (1, '2024-05-21',  4400.00, 'sales',       'May product sales batch 2'),
  (2, '2024-05-30',  6200.00, 'consulting',  'Consulting retainer — Client B'),
  (4, '2024-05-31',  5800.00, 'payroll',     'May salaries'),
  (3, '2024-05-31',  2200.00, 'facilities',  'May rent'),
  (5, '2024-05-31',   320.00, 'utilities',   'May utilities'),
-- June
  (1, '2024-06-10', 12300.00, 'sales',       'Jun product sales — strong quarter close'),
  (2, '2024-06-14',  8400.00, 'consulting',  'Project completion bonus — Client B'),
  (2, '2024-06-28',  6200.00, 'consulting',  'Consulting retainer — Client B'),
  (4, '2024-06-30',  5800.00, 'payroll',     'Jun salaries'),
  (3, '2024-06-30',  2200.00, 'facilities',  'Jun rent'),
  (5, '2024-06-30',   355.00, 'utilities',   'Jun utilities'),
-- July
  (1, '2024-07-09',  7600.00, 'sales',       'Jul product sales batch 1'),
  (2, '2024-07-25',  6200.00, 'consulting',  'Consulting retainer — Client B'),
  (4, '2024-07-31',  5800.00, 'payroll',     'Jul salaries'),
  (3, '2024-07-31',  2400.00, 'facilities',  'Jul rent (annual increase)'),
  (5, '2024-07-31',   410.00, 'utilities',   'Jul utilities (AC — peak summer)'),
-- August
  (1, '2024-08-05',  6900.00, 'sales',       'Aug product sales batch 1'),
  (1, '2024-08-22',  2300.00, 'sales',       'Aug product sales batch 2'),
  (2, '2024-08-29',  4800.00, 'consulting',  'Consulting retainer — Client A (renewed)'),
  (4, '2024-08-31',  5800.00, 'payroll',     'Aug salaries'),
  (3, '2024-08-31',  2400.00, 'facilities',  'Aug rent'),
  (5, '2024-08-31',   390.00, 'utilities',   'Aug utilities'),
-- September
  (1, '2024-09-11', 13500.00, 'sales',       'Sep product sales — enterprise deal'),
  (2, '2024-09-20',  6200.00, 'consulting',  'Consulting retainer — Client B'),
  (2, '2024-09-27',  3100.00, 'consulting',  'Workshop delivery — Client D'),
  (4, '2024-09-30',  5800.00, 'payroll',     'Sep salaries'),
  (3, '2024-09-30',  2400.00, 'facilities',  'Sep rent'),
  (5, '2024-09-30',   305.00, 'utilities',   'Sep utilities'),
-- October
  (1, '2024-10-07',  9800.00, 'sales',       'Oct product sales batch 1'),
  (2, '2024-10-18',  6200.00, 'consulting',  'Consulting retainer — Client B'),
  (4, '2024-10-31',  6100.00, 'payroll',     'Oct salaries (new hire)'),
  (3, '2024-10-31',  2400.00, 'facilities',  'Oct rent'),
  (5, '2024-10-31',   330.00, 'utilities',   'Oct utilities'),
-- November
  (1, '2024-11-04',  8200.00, 'sales',       'Nov product sales batch 1'),
  (1, '2024-11-19',  3700.00, 'sales',       'Nov product sales batch 2'),
  (2, '2024-11-22',  6200.00, 'consulting',  'Consulting retainer — Client B'),
  (4, '2024-11-30',  6100.00, 'payroll',     'Nov salaries'),
  (3, '2024-11-30',  2400.00, 'facilities',  'Nov rent'),
  (5, '2024-11-30',   295.00, 'utilities',   'Nov utilities'),
-- December
  (1, '2024-12-06', 14200.00, 'sales',       'Dec product sales — year-end push'),
  (2, '2024-12-12',  9600.00, 'consulting',  'Annual contract renewal bonus'),
  (2, '2024-12-27',  6200.00, 'consulting',  'Consulting retainer — Client B'),
  (4, '2024-12-31',  6100.00, 'payroll',     'Dec salaries'),
  (3, '2024-12-31',  2400.00, 'facilities',  'Dec rent'),
  (5, '2024-12-31',   340.00, 'utilities',   'Dec utilities');

-- ============================================================
-- Asset account entries (cash reserve movements)
-- ============================================================
INSERT INTO transactions (account_id, txn_date, amount, category, description) VALUES
  (7, '2024-03-31',  10000.00, 'reserve', 'Q1 cash reserve top-up'),
  (7, '2024-06-30',  15000.00, 'reserve', 'Q2 cash reserve top-up'),
  (7, '2024-09-30',   8000.00, 'reserve', 'Q3 cash reserve top-up'),
  (7, '2024-12-31',  20000.00, 'reserve', 'Q4 year-end reserve build');

-- Verify row counts
SELECT account_type, COUNT(*) AS txn_count, ROUND(SUM(amount), 2) AS total
FROM transactions t
JOIN accounts a USING (account_id)
GROUP BY account_type
ORDER BY account_type;