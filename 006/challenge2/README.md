# Flink 모듈 (Challenge 2)

Apache Flink 기반의 Kinesis Data Analytics Studio 앱과 Glue 카탈로그 DB를 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_kinesisanalyticsv2_application` | `gj2026-data-flink` | Flink Studio 앱 (ZEPPELIN-FLINK-3_0) |
| `aws_iam_role` | `gj2026-data-flink-role` | Flink 실행 Role (AdministratorAccess) |
| `aws_glue_catalog_database` | `default` | Glue 기본 카탈로그 DB |
| `aws_glue_catalog_database` | `real_time_analytics` | 실시간 분석용 Glue DB |

---

## 수동 작업

### 1. Flink Studio 앱 시작

Terraform으로 앱이 생성되지만 **실행은 수동**으로 해야 한다.

```bash
# CLI로 시작
aws kinesisanalyticsv2 start-application \
  --application-name gj2026-data-flink

# 상태 확인 (RUNNING 될 때까지 대기)
aws kinesisanalyticsv2 describe-application \
  --application-name gj2026-data-flink \
  --query "ApplicationDetail.ApplicationStatus"
```

---

### 2. AWS 지원 Kafka Connector 추가

Flink에서 Kafka를 사용하려면 AWS에서 제공하는 Kafka Connector를 앱에 추가해야 한다.

```
AWS 콘솔 → Managed Service for Apache Flink
→ gj2026-data-flink → Configure → Connectors
→ Add connector → Apache Kafka 선택
→ Save changes
```
---

### 3. Query 실행

Connector 등록 후 Zeppelin 노트북에서 아래 순서로 쿼리를 실행한다.


#### 3-1. Sink 테이블 생성 (Glue 카탈로그 연동)

```sql
%flink.ssql
USE real_time_analytics;

CREATE TABLE IF NOT EXISTS order_logs (
    order_id         STRING,
    user_id          STRING,
    cart_age_seconds INT,
    status_code      INT,
    latency_ms       INT,
    event_time       BIGINT,
    event_ts         AS TO_TIMESTAMP_LTZ(event_time, 3),
    WATERMARK FOR event_ts AS event_ts - INTERVAL '5' SECOND
) WITH (
    'connector'                    = 'kafka',
    'topic'                        = 'order-logs',
    'properties.bootstrap.servers' = '<gj2026-data-nlb-dns>:9094',
    'properties.group.id'          = 'flink-consumer',
    'scan.startup.mode'            = 'earliest-offset',
    'format'                       = 'json',
    'json.ignore-parse-errors'     = 'true'
);

CREATE TABLE IF NOT EXISTS sink_error_stats (
    window_start   TIMESTAMP(3),
    window_end     TIMESTAMP(3),
    total_count    BIGINT,
    error_count    BIGINT,
    error_rate     DOUBLE,
    avg_latency_ms DOUBLE
) WITH (
    'connector'                    = 'kafka',
    'topic'                        = 'error-stats',
    'properties.bootstrap.servers' = '<gj2026-data-nlb-dns>:9094',
    'format'                       = 'json'
);

CREATE TABLE IF NOT EXISTS sink_high_latency (
    order_id       STRING,
    user_id        STRING,
    latency_ms     INT,
    avg_latency_ms DOUBLE,
    proc_time      STRING,
    is_anomaly     INT
) WITH (
    'connector'                    = 'kafka',
    'topic'                        = 'high-latency',
    'properties.bootstrap.servers' = '<gj2026-data-nlb-dns>:9094',
    'format'                       = 'json'
);

CREATE TABLE IF NOT EXISTS sink_anomaly (
    user_id             STRING,
    order_count         BIGINT,
    rate_limit_count    BIGINT,
    bot_suspected_count BIGINT,
    anomaly_type        STRING,
    window_start        TIMESTAMP(3),
    window_end          TIMESTAMP(3)
) WITH (
    'connector'                    = 'kafka',
    'topic'                        = 'anomaly',
    'properties.bootstrap.servers' = '<gj2026-data-nlb-dns>:9094',
    'format'                       = 'json'
);
```

#### 3-2. 분석 쿼리 실행 (Streaming INSERT)

```sql
%flink.ssql
BEGIN STATEMENT SET;

INSERT INTO sink_error_stats
SELECT
    window_start,
    window_end,
    COUNT(*) AS total_count,
    COUNT(CASE WHEN status_code >= 400 THEN 1 END) AS error_count,
    ROUND(COUNT(CASE WHEN status_code >= 400 THEN 1 END) * 100.0 / COUNT(*), 2) AS error_rate,
    ROUND(AVG(latency_ms), 2) AS avg_latency_ms
FROM TABLE(HOP(TABLE order_logs, DESCRIPTOR(event_ts), INTERVAL '30' SECOND, INTERVAL '2' MINUTE))
GROUP BY window_start, window_end;

INSERT INTO sink_high_latency
SELECT
    order_id,
    user_id,
    latency_ms,
    avg_latency_ms,
    CAST(event_ts AS STRING) AS proc_time,
    CASE WHEN latency_ms > 500 THEN 1 ELSE 0 END AS is_anomaly
FROM (
    SELECT
        order_id,
        user_id,
        latency_ms,
        AVG(CAST(latency_ms AS DOUBLE)) OVER (
            PARTITION BY user_id
            ORDER BY event_ts
            ROWS BETWEEN 99 PRECEDING AND CURRENT ROW
        ) AS avg_latency_ms,
        event_ts
    FROM order_logs
)
WHERE latency_ms > avg_latency_ms;

INSERT INTO sink_anomaly
SELECT
    user_id,
    COUNT(*) AS order_count,
    COUNT(CASE WHEN status_code = 429 THEN 1 END) AS rate_limit_count,
    COUNT(CASE WHEN cart_age_seconds < 3 THEN 1 END) AS bot_suspected_count,
    CASE
        WHEN COUNT(CASE WHEN cart_age_seconds < 3 THEN 1 END) * 1.0 / COUNT(*) > 0.8 THEN 'BOT_SUSPECTED'
        WHEN COUNT(CASE WHEN status_code = 429 THEN 1 END) * 1.0 / COUNT(*) > 0.5   THEN 'RATE_LIMITED'
        WHEN COUNT(*) > 150                                                            THEN 'EXCESSIVE_ORDER'
        ELSE 'NORMAL'
    END AS anomaly_type,
    window_start,
    window_end
FROM TABLE(HOP(TABLE order_logs, DESCRIPTOR(event_ts), INTERVAL '30' SECOND, INTERVAL '2' MINUTE))
GROUP BY user_id, window_start, window_end
HAVING
    COUNT(CASE WHEN cart_age_seconds < 3 THEN 1 END) * 1.0 / COUNT(*) > 0.8
    OR COUNT(CASE WHEN status_code = 429 THEN 1 END) * 1.0 / COUNT(*) > 0.5
    OR COUNT(*) > 150;

END;
```

> Zeppelin에서 `%flink.ssql(type=update)`로 실행해야 Streaming 쿼리가 지속적으로 동작함

---

## 주의사항

> `ignore_changes = [application_configuration]` 설정으로 콘솔에서 변경한 Connector·설정을 Terraform이 덮어쓰지 않음

---

## Outputs

| 이름 | 설명 |
|------|------|
| `flink_app_name` | Kinesis Analytics 앱 이름 |
| `flink_app_arn` | 앱 ARN |
