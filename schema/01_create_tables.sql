-- ============================================================
-- FinPulse Analytics — Schema
-- Author: Derrick Mukisa
-- Description: Core tables for financial transaction analysis
-- PostgreSQL 15+
-- ============================================================

CREATE DATABASE finpulse;
\c finpulse

CREATE TABLE accounts (
  account_id   SERIAL PRIMARY KEY,
  account_name TEXT NOT NULL,
  account_type TEXT NOT NULL
    CHECK (account_type IN ('revenue', 'expense', 'asset')),
  parent_account_id INT REFERENCES accounts(account_id)
);

CREATE TABLE transactions (
  txn_id      SERIAL PRIMARY KEY,
  account_id  INT NOT NULL REFERENCES accounts(account_id),
  txn_date    DATE NOT NULL,
  amount      NUMERIC(12,2) NOT NULL,
  category    TEXT,
  description TEXT
);

CREATE INDEX idx_txn_date     ON transactions(txn_date);
CREATE INDEX idx_txn_account  ON transactions(account_id);
CREATE INDEX idx_txn_date_account ON transactions (account_id, txn_date);