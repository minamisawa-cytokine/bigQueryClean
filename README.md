# BigQuery テーブル使用状況調査ツール

BigQueryプロジェクト内の全データセット・テーブルの使用状況を調査し、使われていないテーブルを特定するためのSQLクエリセットです。

## 概要

このツールは以下の情報を収集します：
- データセット名、テーブル名
- テーブルタイプ（TABLE、VIEW、EXTERNAL_TABLE等）
- 作成日、最終更新日
- 最終API/プログラムクエリ日時（ブラウザプレビュー除外）
- 行数、テーブルサイズ（バイト数）
- パーティション情報

## ファイル構成

- `create_table.sql` - 結果格納用テーブル作成
- `collect_table_info.sql` - データ収集・挿入クエリ
- `query_results.sql` - 結果確認・分析クエリ

## 使用方法

### 前提条件

1. BigQueryプロジェクトへの読み取り権限
2. `cleaning`データセットへの書き込み権限
3. `INFORMATION_SCHEMA`へのアクセス権限

### 実行手順

#### 1. テーブル作成

BigQuery Consoleで以下を実行：

```sql
-- create_table.sql の内容をコピー&ペースト
```

#### 2. データ収集

BigQuery Consoleで以下を実行：

```sql
-- collect_table_info.sql の内容をコピー&ペースト
```

#### 3. 結果確認

BigQuery Consoleで以下を実行：

```sql
-- query_results.sql の内容をコピー&ペースト
```

## 出力項目

| 項目名 | 説明 |
|--------|------|
| dataset_name | データセット名 |
| table_name | テーブル名 |
| table_type | テーブルタイプ |
| creation_time | 作成日時 |
| last_modified_time | 最終更新日時 |
| last_query_time | 最終クエリ実行日時 |
| row_count | 行数 |
| size_gb | テーブルサイズ（GB） |
| partition_type | パーティションタイプ |
| usage_status | 使用状況（自動判定） |
| days_since_last_query | 最終クエリからの経過日数 |

## 使用状況の判定基準

- **クエリ履歴なし**: 過去1年間にクエリ実行履歴がない
- **90日以上未使用**: 最終クエリから90日以上経過
- **30日以上未使用**: 最終クエリから30日以上経過
- **最近使用**: 30日以内にクエリ実行

## 注意事項

- ブラウザでの「プレビュー」は最終クエリ日時から除外されます
- システム内部クエリ（@google.com、service-account）は除外されます
- 過去1年間のクエリログを対象としています
- パーティションカラム名は現在のバージョンでは取得できません

## カスタマイズ

### 判定期間の変更

`collect_table_info.sql`の以下の行を修正：

```sql
-- 過去1年間 → 過去6ヶ月間に変更する場合
AND creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
```

### 除外条件の追加

特定のデータセットやテーブルを除外する場合：

```sql
WHERE table_schema != 'INFORMATION_SCHEMA'
  AND table_schema NOT IN ('system_dataset', 'temp_dataset')  -- 追加
```

## トラブルシューティング

### 権限エラーが発生する場合

- BigQuery Data Viewer権限を確認
- cleaning データセットへのBigQuery Data Editor権限を確認

### データが取得できない場合

- INFORMATION_SCHEMAへのアクセス権限を確認
- リージョン設定（region-us）がプロジェクトと一致するか確認

## ライセンス

MIT License