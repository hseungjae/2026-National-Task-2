# Module 2 - Flink Studio (실시간 분석)

## Terraform 배포

```bash
terraform init
terraform apply --auto-approve
```

## 수동 작업 (Console)

### 1. Flink Studio 시작
1. AWS Console → Amazon Kinesis → Analytics applications → `wsc2026-analytics-flink`
2. **Open in Apache Zeppelin** 클릭
3. Studio Notebook이 **READY** 상태가 될 때까지 대기

### 2. Flink Studio Kinesis Connector 추가

1. `wsc2026-analytics-flink` 앱 선택 → **Configuration** 탭
2. **Connectors** 섹션 → **Add connector** 클릭
3. AWS 제공 connector 목록에서 **flink-sql-connector-kinesis, flink-connector-kafka, aws-mks-iam-auth** 선택
4. **Save changes** 클릭
5. 앱 재시작 (Stop → Open in Apache Zeppelin)

### 3. Zeppelin에서 Kinesis 테이블 생성

```sql
%flink.ssql

DROP TABLE IF EXISTS order_stream;

CREATE TABLE order_stream (
  order_id     STRING,
  product_name STRING,
  price        BIGINT,
  quantity     INT,
  event_time   TIMESTAMP_LTZ(3),
  WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
)
WITH (
  'connector'                      = 'kinesis',
  'stream'                         = 'wsc2026-order-stream',
  'aws.region'                     = 'ap-northeast-2',
  'scan.stream.initpos'            = 'TRIM_HORIZON',
  'format'                         = 'json',
  'json.timestamp-format.standard' = 'SQL'
);
```

### 3. 분석 쿼리 실행
문제지에 SQL 쿼리 
```
SELECT COUNT(*) as order_count
  FROM order_stream
  WHERE event_time > CURRENT_TIMESTAMP - INTERVAL '1' MINUTE;

SELECT product_name, SUM(price * quantity) as total_revenue
  FROM order_stream
  GROUP BY product_name;
```

## 채점 스크립트

```bash
./mark2-2.sh
```
