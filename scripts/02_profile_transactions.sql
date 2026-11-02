-- ============================================================
-- Step 4: Data quality rules - Berka dataset
-- Script 02: Profile raw_trans (look before writing rules)
-- ============================================================


-- 1. Values in the direction column (type): which values exist and how often?
SELECT type, COUNT(*) AS row_count
FROM raw_trans
GROUP BY type
ORDER BY row_count DESC;


-- 2. Amount: can every value be read as a number?
-- (rows where the text cannot be converted)
SELECT COUNT(*) AS not_a_number
FROM raw_trans
WHERE TRY_CAST(amount AS DECIMAL(18,2)) IS NULL;


-- 3. Amount: how many are zero or negative? (rule: greater than zero)
SELECT COUNT(*) AS amount_not_positive
FROM raw_trans
WHERE TRY_CAST(amount AS DECIMAL(18,2)) <= 0;


-- 4. Amount: show those rows so we can see what they look like
SELECT *
FROM raw_trans
WHERE TRY_CAST(amount AS DECIMAL(18,2)) <= 0;


-- 5. Date: can every value be read as a date? (format YYMMDD)
SELECT COUNT(*) AS invalid_date
FROM raw_trans
WHERE TRY_STRPTIME(date, '%y%m%d') IS NULL;


-- 6. Uniqueness of the transaction identifier
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT trans_id) AS distinct_ids
FROM raw_trans;


