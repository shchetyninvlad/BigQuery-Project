--Виводжу поля та витягую session_num з массиву
WITH user_session AS(
  SELECT DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date
    , traffic_source.source AS source
    , traffic_source.medium AS medium
    , traffic_source.name AS campaign
    , user_pseudo_id
    , event_name
    , (SELECT value.int_value FROM UNNEST(event_params) WHERE key = "ga_session_id") AS session_num
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name IN('session_start','add_to_cart','begin_checkout','purchase')
),
--Виявляю чи трапилась певна подія в сессії
session_flags AS (
  SELECT event_date
    , source
    , medium
    , campaign
    , CONCAT(user_pseudo_id, session_num) AS session_id 
    , IF(COUNTIF(event_name = 'session_start') > 0, 1, 0) AS has_session_start
    , IF(COUNTIF(event_name = 'add_to_cart') > 0, 1, 0) AS has_add_to_cart
    , IF(COUNTIF(event_name = 'begin_checkout') > 0, 1, 0) AS has_begin_checkout
    , IF(COUNTIF(event_name = 'purchase') > 0, 1, 0) AS has_purchase
  FROM user_session
  GROUP BY event_date, source, medium, campaign, session_id
), 
--Знаходжу унікальну кількість сесій та агрегую кожну подію з унікальними session_id для виявлення конверсії
aggregation AS (
  SELECT event_date
      , source
      , medium
      , campaign
      , COUNT(DISTINCT session_id) AS user_sessions_count
      , ROUND(SUM(has_add_to_cart) / COUNT(DISTINCT session_id), 4) AS visit_to_cart
      , ROUND(SUM(has_begin_checkout) / COUNT(DISTINCT session_id), 4) AS visit_to_checkout
      , ROUND(SUM(has_purchase) / COUNT(DISTINCT session_id), 4) AS visit_to_purchase
    FROM session_flags
    WHERE has_session_start = 1  -- рахуємо тільки сесії, які почались
    GROUP BY event_date, source, medium, campaign
)
-- Змінюю 'видаленні данні з (source,medium,campaign) на 'невідомі'. Та вивиожу необхідні поля.
SELECT event_date
  , COALESCE(NULLIF(source, '(data deleted)'), 'unknown') AS source 
  , COALESCE(NULLIF(medium, '(data deleted)'), 'unknown') AS medium
  , COALESCE(NULLIF(campaign, '(data deleted)'), 'unknown') AS campaign
  , user_sessions_count
  , visit_to_cart
  , visit_to_checkout
  , visit_to_purchase
FROM aggregation
