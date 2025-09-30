# BigQuery-Project
###  1. BigQuery – GA4 Events Table (2021)
Формує таблицю подій GA4 за **2021 рік** з полями:
- `event_timestamp` (TIMESTAMP)
- `user_pseudo_id`
- `session_id` (із `event_params['ga_session_id']`)
- `event_name`
- `country`, `device_category`
- `source`, `medium`, `campaign`

**Джерело даних:** `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`  
**Фільтр по даті:** `_TABLE_SUFFIX BETWEEN '20210101' AND '20211231'`  
**Список подій у вибірці:** `session_start`, `view_item`, `add_to_chat`, `begig-checkout`, `add_shipping_info`, `add_payment_info`, `purchase`.

[📁 View SQL](./task_bq_2_ga4_events_2021.sql)

###  2. BigQuery – Conversions by Date & Channel (GA4)
Розрахунок конверсій від `session_start` до ключових подій у розрізі **дата × source × medium × campaign**.

**Поля у результаті**
- `event_date` – дата старту сесії (із `event_timestamp`)
- `source`, `medium`, `campaign`
- `user_sessions_count` – унікальні сесії унікальних користувачів (ключ = `user_pseudo_id + ga_session_id`)
- `visit_to_cart`, `visit_to_checkout`, `visit_to_purchase` – частка сесій з відповідною подією

**Логіка**
- Витяг `ga_session_id` із `event_params`
- Формування `session_id = CONCAT(user_pseudo_id, ga_session_id)`
- Прапорці подій по сесії та агрегація по групах

**Джерело:** `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

[📁 View SQL](./task_bq_3_conversions_by_channel.sql)

###  3. BigQuery – Landing Page Conversion (2020)
Порівняння конверсії між посадковими сторінками (GA4, 2020). Для кожного `page_path` (шлях із `session_start.page_location`) обчислює:
- `unique_sessions` — унікальні сесії унікальних користувачів (ключ = `user_pseudo_id + ga_session_id`)
- `purchases` — кількість сесій із подією `purchase`
- `session_to_purchase_conversion` — частка сесій із покупкою

**Період:** 2020 рік  
**Події:** `session_start`, `purchase`  
**Виділення шляху сторінки:** `REGEXP_EXTRACT(page_location, r'https?://[^/]+(/[^?]*)')`

[📁 View SQL](./task_bq_4_landing_page_conversion_2020.sql)

###  4. BigQuery – Engagement vs Purchase Correlation (GA4)
Для кожної унікальної сесії визначає:
- `session_engaged` (за `event_params['session_engaged']`)
- `sum_eng_time` – сума `engagement_time_msec` за подіями сесії
- `purchase_check` – індикатор наявності покупки у сесії

Далі обчислює коефіцієнти кореляції:
- `corr(sum_eng_time, purchase_check)`
- `corr(session_engaged, purchase_check)`

**Ключ сесії:** `user_session_id = user_pseudo_id + ga_session_id`  
**Джерело:** `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

[📁 View SQL](./task_bq_5_engagement_purchase_correlation.sql)




