SELECT timestamp_micros(event_timestamp) AS event_timestamp
  , user_pseudo_id 
  , (select p.value.int_value from e.event_params as p where p.key = 'ga_session_id') as session_id
  , event_name
  , geo.country AS country
  , device.category AS device_category
  , traffic_source.source AS source 
  , traffic_source.medium AS medium 
  , traffic_source.name as campaign 
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
WHERE (_TABLE_SUFFIX BETWEEN '20210101' AND '20211231')
AND event_name IN ('session_start', 'view_item', 'add_to_chat', 'begig-checkout', 'add_shipping_info', 'add_payment_info', 'purchase')
