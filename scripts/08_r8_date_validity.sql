-- Script 08: Dates are not in the future (rule R8, Validity)
-- LIMIT: delay between event and recording cannot be measured (no load times in Berka).
-- NOTE: with %y, two-digit years 00-68 are read as 2000-2068, so future dates are detected.

-- 8.1 Real data
SELECT 'R8' AS rule_id, 'Dates are not in the future' AS rule, 'Validity' AS dimension,
       (SELECT COUNT(*) FROM raw_trans) + (SELECT COUNT(*) FROM raw_account) AS rows_checked,
       (SELECT COUNT(*) FROM raw_trans   WHERE TRY_STRPTIME(date, '%y%m%d') > CURRENT_DATE)
     + (SELECT COUNT(*) FROM raw_account WHERE TRY_STRPTIME(date, '%y%m%d') > CURRENT_DATE) AS rows_failed;

-- 8.2 Latest dates in the data (the data's cut-off)
SELECT MAX(TRY_STRPTIME(date, '%y%m%d')) AS latest_transaction FROM raw_trans;

-- 8.3 Synthetic test (labelled, on the copy from Script 05)
INSERT INTO test_trans VALUES
  ('9000003', '999002', '300101', 'PRIJEM', 'VKLAD', '100.00', '100.00', NULL, NULL, NULL, 'synthetic');

SELECT COUNT(*) AS rows_checked,
       COUNT(*) FILTER (WHERE TRY_STRPTIME(date, '%y%m%d') > CURRENT_DATE) AS rows_failed,
       1 AS expected_failures
FROM test_trans;
                              
                              
  -- 8.4. Date ranges (checks the YYMMDD assumption)
SELECT 'account' AS tbl, MIN(TRY_STRPTIME(date, '%y%m%d')) AS first_date, MAX(TRY_STRPTIME(date, '%y%m%d')) AS last_date FROM raw_account
UNION ALL
SELECT 'trans', MIN(TRY_STRPTIME(date, '%y%m%d')), MAX(TRY_STRPTIME(date, '%y%m%d')) FROM raw_trans;

