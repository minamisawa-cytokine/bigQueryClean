-- BigQuery テーブル使用状況データ収集・挿入クエリ
-- 現在のプロジェクトの全データセット・テーブル情報を収集


INSERT INTO `cleaning.table_inventory` (
  dataset_name,
  table_name,
  table_type,
  creation_time,
  last_modified_time,
  last_query_time,
  row_count,
  size_bytes,
  partition_type,
  partition_column
)
WITH table_info AS (
  -- テーブル基本情報を取得
  SELECT 
    table_schema as dataset_name,
    table_name,
    table_type,
    creation_time,
    TIMESTAMP_MILLIS(last_modified_time) as last_modified_time,
    row_count,
    size_bytes
  FROM `searchconsole-293711.INFORMATION_SCHEMA.TABLES`  -- PROJECT_ID を変更する場合はここも変更
  WHERE table_schema != 'INFORMATION_SCHEMA'
),
last_query_info AS (
  -- 最終クエリ実行日時を取得（APIクエリのみ、プレビュー除外）
  SELECT 
    referenced_tables.dataset_id as dataset_name,
    referenced_tables.table_id as table_name,
    MAX(creation_time) as last_query_time
  FROM `searchconsole-293711.INFORMATION_SCHEMA.JOBS_BY_PROJECT`,  -- PROJECT_ID を変更する場合はここも変更
  UNNEST(referenced_tables) as referenced_tables
  WHERE 
    job_type = 'QUERY'
    AND state = 'DONE'
    AND error_result IS NULL
    -- システム内部クエリを除外
    AND user_email NOT LIKE '%@google.com'
    AND user_email NOT LIKE '%service-account%'
    -- 過去1年間のクエリログを対象
    AND creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
  GROUP BY 1, 2
)
SELECT 
  ti.dataset_name,
  ti.table_name,
  ti.table_type,
  ti.creation_time,
  ti.last_modified_time,
  lqi.last_query_time,
  ti.row_count,
  ti.size_bytes,
  CAST(NULL AS STRING) as partition_type,
  CAST(NULL AS STRING) as partition_column
FROM table_info ti
LEFT JOIN last_query_info lqi 
  ON ti.dataset_name = lqi.dataset_name 
  AND ti.table_name = lqi.table_name
ORDER BY ti.dataset_name, ti.table_name;
