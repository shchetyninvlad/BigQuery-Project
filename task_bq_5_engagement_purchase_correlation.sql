with user_session_id_info AS (
  --Виводжу необхідні данні з массиву та обробляю, перетворюю тип данних, роблю перевірку purchase через case
  SELECT  user_pseudo_id
  , (SELECT value.int_value FROM UNNEST(event_params) WHERE key = "ga_session_id") AS session_num 
  , COALESCE((SELECT value.int_value FROM UNNEST(event_params) WHERE key = "engagement_time_msec"), 0) AS user_eng_time
  , COALESCE(SAFE_CAST((SELECT value. string_value FROM UNNEST(event_params) WHERE key = "session_engaged")AS INT64), 0) AS session_engaged
  , CASE 
      WHEN event_name = 'purchase'
      THEN 1
      ELSE 0
    END AS purchase_check
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),
--Створюю унікальні сесії та агрегую отримані вище данні 
aggregate AS (
SELECT CONCAT(user_pseudo_id, session_num) AS user_session_id
  , SUM(user_eng_time) AS sum_eng_time
  , MAX(session_engaged) AS session_engaged
  , MAX(purchase_check) AS purchase_check
FROM user_session_id_info
GROUP BY 1
ORDER BY 1
)
-- Рахую кореляцію між залученістю користувачів та здійсненням покупок
SELECT corr(sum_eng_time,purchase_check) AS corr_engtime_purchase
  , corr(session_engaged,purchase_check) AS corr_engaged_purchase
FROM aggregate
