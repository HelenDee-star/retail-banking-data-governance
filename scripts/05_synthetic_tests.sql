-- ============================================================
-- Step 4: Data quality rules - Berka dataset
-- Script 05: Synthetic test of rules that found 0 failures
--
-- PURPOSE: R1a, R1b, R3 and R4 found no failures on the real data. That
--   could mean the data is clean, or that the rule cannot catch anything.
--   Here we add a few rows that deliberately break each rule and check
--   that the same rule logic detects them.
-- LABELLING: every added row has source = 'synthetic'. All other rows have
--   source = 'berka'. These rows are NOT Berka data and are NOT counted in
--   the results of Script 04.
-- SAFETY: the raw_ tables are never changed. We work on copies (test_ tables).
-- ============================================================


-- 1. Make copies of the raw tables, with a source label on every row
CREATE OR REPLACE TABLE test_account AS
SELECT *, 'berka' AS source FROM raw_account;

CREATE OR REPLACE TABLE test_trans AS
SELECT *, 'berka' AS source FROM raw_trans;


-- 2. Add synthetic rows
-- Account columns: account_id, district_id, frequency, date, source
INSERT INTO test_account VALUES
  ('999001', '1', 'POPLATEK MESICNE', '970101', 'synthetic'),  -- R1a: same ID...
  ('999001', '1', 'POPLATEK MESICNE', '970101', 'synthetic'),  -- ...used twice
  ('999002', '1', 'POPLATEK MESICNE', '970101', 'synthetic'),  -- valid account, opened 1 Jan 1997
  ('',       '1', 'POPLATEK MESICNE', '970101', 'synthetic'),  -- R1b: empty ID
  ('   ',    '1', 'POPLATEK MESICNE', '970101', 'synthetic');  -- R1b: blank ID

-- Transaction columns: trans_id, account_id, date, type, operation, amount,
--                      balance, k_symbol, bank, account, source
INSERT INTO test_trans VALUES
  ('9000001', '999002', '960101', 'PRIJEM', 'VKLAD', '1000.00', '1000.00', NULL, NULL, NULL, 'synthetic'),  -- R3: dated 1996, before opening 1997
  ('9000002', '999002', '980101', 'XYZ',    'VKLAD', '500.00',  '1500.00', NULL, NULL, NULL, 'synthetic');  -- R4: invalid type


-- 3. Run the same rule logic as Script 04 on the test tables
SELECT rule_id, rule, rows_checked, rows_failed, expected_failures,
       CASE WHEN rows_failed = expected_failures THEN 'PASS (rule caught it)'
            ELSE 'FAIL (check rule)' END AS test_result
FROM (
    SELECT 'R1a' AS rule_id, 'Account ID is unique' AS rule,
           COUNT(*) AS rows_checked,
           COUNT(*) - COUNT(DISTINCT account_id) AS rows_failed,
           1 AS expected_failures
    FROM test_account

    UNION ALL
    SELECT 'R1b', 'Account ID is not empty', COUNT(*),
           COUNT(*) FILTER (WHERE account_id IS NULL OR TRIM(account_id) = ''), 2
    FROM test_account

    UNION ALL
    SELECT 'R3', 'Transaction date not before account opening date', COUNT(*),
           COUNT(*) FILTER (WHERE TRY_STRPTIME(t.date, '%y%m%d') < TRY_STRPTIME(a.date, '%y%m%d')), 1
    FROM test_trans t
    JOIN test_account a ON t.account_id = a.account_id

    UNION ALL
    SELECT 'R4', 'Direction maps to D or C', COUNT(*),
           COUNT(*) FILTER (WHERE type NOT IN ('PRIJEM', 'VYDAJ', 'VYBER')), 1
    FROM test_trans
)
ORDER BY rule_id;


-- 4. List the synthetic rows (so they can always be identified)
SELECT 'account' AS tbl, account_id AS id, source FROM test_account WHERE source = 'synthetic'
UNION ALL
SELECT 'trans', trans_id, source FROM test_trans WHERE source = 'synthetic';  -- 5. Synthetic test for R9 (every Account has at least one OWNER)
-- Berka has exactly one OWNER per account, so R9 found 0 failures.
-- This adds one account with no OWNER row and checks the rule catches it.
-- The earlier synthetic accounts are given OWNER rows so that only 999003 should fail.

CREATE OR REPLACE TABLE test_disp AS
SELECT *, 'berka' AS source FROM raw_disp;

-- Account with no OWNER row (the one that should be caught)
INSERT INTO test_account VALUES
  ('999003', '1', 'POPLATEK MESICNE', '970101', 'synthetic');

-- OWNER rows for the other synthetic accounts: disp_id, client_id, account_id, type, source
INSERT INTO test_disp VALUES
  ('990001', '9990001', '999001', 'OWNER', 'synthetic'),
  ('990002', '9990002', '999002', 'OWNER', 'synthetic'),
  ('990003', '9990003', '',       'OWNER', 'synthetic'),
  ('990004', '9990004', '   ',    'OWNER', 'synthetic');

SELECT 'R9' AS rule_id,
       COUNT(*) AS rows_checked,
       COUNT(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM test_disp d
                                          WHERE d.account_id = a.account_id
                                            AND d.type = 'OWNER')) AS rows_failed,
       1 AS expected_failures
FROM test_account a;

