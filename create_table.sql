-- BigQuery テーブル使用状況調査用テーブル作成
-- cleaning データセットに table_inventory テーブルを作成

CREATE OR REPLACE TABLE `cleaning.table_inventory` (
  dataset_name STRING NOT NULL,
  table_name STRING NOT NULL,
  table_type STRING,
  creation_time TIMESTAMP,
  last_modified_time TIMESTAMP,
  last_query_time TIMESTAMP,
  row_count INT64,
  size_bytes INT64,
  partition_type STRING,
  partition_column STRING,
  collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(collected_at)
OPTIONS(
  description="BigQueryテーブル使用状況調査結果",
  labels=[("purpose", "table_analysis"), ("team", "data_engineering")]
);