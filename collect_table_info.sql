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
  FROM `region-us.INFORMATION_SCHEMA.TABLES`
  WHERE table_schema != 'INFORMATION_SCHEMA'
),
partition_info AS (
  -- パーティション情報を取得
  SELECT 
    table_schema as dataset_name,
    table_name,
    partition_id,
    CASE 
      WHEN partition_id LIKE '%$%' THEN 'TIME_PARTITIONING'
      WHEN partition_id != '__NULL__' THEN 'RANGE_PARTITIONING'
      ELSE NULL
    END as partition_type,
    -- パーティションカラム名は直接取得できないため、別途調査が必要
    CAST(NULL AS STRING) as partition_column
  FROM `region-us.INFORMATION_SCHEMA.PARTITIONS`
  WHERE partition_id != '__UNPARTITIONED__'
  GROUP BY 1, 2, 3, 4
),
last_query_info AS (
  -- 最終クエリ実行日時を取得（APIクエリのみ、プレビュー除外）
  SELECT 
    referenced_tables.dataset_id as dataset_name,
    referenced_tables.table_id as table_name,
    MAX(creation_time) as last_query_time
  FROM `region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`,
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
  pi.partition_type,
  pi.partition_column
FROM table_info ti
LEFT JOIN partition_info pi 
  ON ti.dataset_name = pi.dataset_name 
  AND ti.table_name = pi.table_name
LEFT JOIN last_query_info lqi 
  ON ti.dataset_name = lqi.dataset_name 
  AND ti.table_name = lqi.table_name
ORDER BY ti.dataset_name, ti.table_name;