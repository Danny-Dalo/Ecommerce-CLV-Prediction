SELECT * FROM transactions;

-- Getting transaction date range (2016-06-30 to 2022-07-31)
SELECT 
    MIN(created_at) AS earliest_date,
    MAX(created_at) AS latest_date
FROM transactions;

-- Every month from the start to end date range is present
SELECT EXTRACT('year' FROM created_at) as transaction_year,
 EXTRACT('month' FROM created_at) as transaction_month,
COUNT(*)
FROM transactions
GROUP BY 1, 2
ORDER BY 1, 2;

-- 2022 transactions will be for predictions ('future') transactions
-- transactions i year before 2022 will be used as our observation window for past transactions
CREATE VIEW observation_window AS
SELECT * FROM transactions
WHERE created_at >= DATE '2021-01-01'
  AND created_at <  DATE '2021-01-01' + INTERVAL '1 year'
  AND payment_status = 'Success' -- only successful payments count
ORDER BY created_at;


CREATE VIEW prediction_window AS
SELECT *
FROM transactions
WHERE created_at >= DATE '2022-01-01'
  AND created_at <  DATE '2022-01-01' + INTERVAL '7 months'
  AND payment_status = 'Success'
ORDER BY created_at;



-- A table of features relating to each unique customer
CREATE VIEW customer_features AS
SELECT
    customer_id,
    COUNT(DISTINCT booking_id) AS transaction_count, -- frequency
    COUNT(promo_code) AS promo_code_used,
	SUM((item->> 'quantity')::INT) as quantity,
    SUM(total_amount) AS total_spent,	-- monetary
    AVG(total_amount) AS avg_order_value,
	MIN(created_at) AS first_purchase_date,
    MAX(created_at) AS last_purchase_date,
	DATE '2022-01-01' - MAX(created_at) AS recency, -- recency
	DATE '2022-01-01' - MIN(created_at) AS customer_age,	-- tenure
    COUNT(DISTINCT payment_method) AS payment_method_count
FROM observation_window,
jsonb_array_elements(REPLACE(product_metadata, '''', '"')::jsonb) AS item --extract the quamtity from json string
GROUP BY customer_id;




-- How much customers have generated 6 months after observation window

-- Every transaction made from the beginning of 2022
CREATE OR REPLACE VIEW clv_target AS
SELECT customer_id,
MIN(created_at) as first_purchase_date,     -- The first day of 2022
MAX(created_at) as last_purchase_date,  -- The last day of prediction window
SUM(total_amount) as total_spent
FROM prediction_window 
GROUP BY customer_id;

SELECT * FROM clv_target;
-- clv_target is the feature we want to predict



-- Combine independent and dependent variables to one main table
CREATE OR REPLACE VIEW clv_data AS
SELECT 
    feat.*, 
    COALESCE(t.total_spent, 0) AS future_spend  --replace NULL spend with 0
FROM customer_features feat
LEFT JOIN clv_target t 	-- we're keeping every customer info from customer_features view
ON feat.customer_id = t.customer_id;

SELECT * FROM clv_data;


-- 9594 customers did not spend anything
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN future_spend = 0 THEN 1 ELSE 0 END) AS zero_clv_customers	-- 1+1+1+1..+1
FROM clv_data;






-- observation_window count: 245138
-- prediction_window count: 186162
-- customer_features count: 36086
-- clv_target count: 32423
-- clv_data count: 36086
-- clv_date does not contain ANY transactions within the prediction window





