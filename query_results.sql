-- BigQuery テーブル使用状況調査結果の確認クエリ
-- 収集したデータを分析用に表示

-- 基本的な結果確認
SELECT 
  dataset_name,
  table_name,
  table_type,
  creation_time,
  last_modified_time,
  last_query_time,
  row_count,
  ROUND(size_bytes / 1024 / 1024 / 1024, 2) as size_gb,
  partition_type,
  collected_at,
  -- 使用状況の簡易判定
  CASE 
    WHEN last_query_time IS NULL THEN 'クエリ履歴なし'
    WHEN last_query_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY) THEN '90日以上未使用'
    WHEN last_query_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY) THEN '30日以上未使用'
    ELSE '最近使用'
  END as usage_status,
  -- 最終クエリからの経過日数
  DATE_DIFF(CURRENT_DATE(), DATE(last_query_time), DAY) as days_since_last_query
FROM `cleaning.table_inventory`
ORDER BY 
  CASE 
    WHEN last_query_time IS NULL THEN 1
    ELSE 0
  END,
  last_query_time ASC,
  size_bytes DESC;

-- サマリー統計
-- SELECT 
--   COUNT(*) as total_tables,
--   COUNT(CASE WHEN last_query_time IS NULL THEN 1 END) as never_queried,
--   COUNT(CASE WHEN last_query_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY) THEN 1 END) as unused_90_days,
--   COUNT(CASE WHEN last_query_time < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY) THEN 1 END) as unused_30_days,
--   ROUND(SUM(size_bytes) / 1024 / 1024 / 1024, 2) as total_size_gb,
--   ROUND(SUM(CASE WHEN last_query_time IS NULL THEN size_bytes ELSE 0 END) / 1024 / 1024 / 1024, 2) as unused_size_gb
-- FROM `cleaning.table_inventory`;