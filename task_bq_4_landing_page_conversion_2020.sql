--Витягую необхідні події
WITH p_lockation AS(
  SELECT (select value.string_value FROM UNNEST (event_params) WHERE key = 'page_location') as page_location
    , (SELECT value.int_value FROM UNNEST(event_params) WHERE key = "ga_session_id") AS session_num
    , user_pseudo_id
    , event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE (_TABLE_SUFFIX BETWEEN '20200101' AND '20201231') AND event_name IN ('session_start', 'purchase')
),
--Створення унікальних сесій та page_path з умовою session_start. Та знаходимо івенти що мали покупки
session_info AS(
  SELECT CONCAT(user_pseudo_id, session_num) AS session_id
    , MAX(IF(event_name = 'session_start', REGEXP_EXTRACT(page_location, r'https?://[^/]+(/[^?]*)'), NULL)) AS session_start_path
    , COUNTIF(event_name = 'purchase') > 0 AS has_purchase
  FROM p_lockation
  GROUP BY session_id
)
--Рахую кількість унікальних сесій, кількість покупок. Та рахую конверсію від початку сесії до покупки
SELECT session_start_path AS page_path
  , COUNT(*) AS unique_sessions
  , COUNTIF(has_purchase) AS purchases
  , SAFE_DIVIDE(COUNTIF(has_purchase), COUNT(*)) AS session_to_purchase_conversion 
FROM session_info
GROUP BY page_path
ORDER BY unique_sessions DESC
