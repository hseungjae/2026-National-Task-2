import json
import boto3
import datetime

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('wsc2026-target-db')


class ValidationError(Exception):
    pass


def lambda_handler(event, context):
    try:
        # EventBridge 이벤트면 S3에서 읽고, 직접 호출이면 event를 데이터로 사용
        detail = event.get('detail', {})
        bucket = detail.get('bucket', {}).get('name')
        key = detail.get('object', {}).get('key')

        if bucket and key:
            response = s3.get_object(Bucket=bucket, Key=key)
            content = json.loads(response['Body'].read().decode('utf-8'))
        else:
            content = event

        # 필수 필드 검증
        if 'id' not in content or content.get('id') is None:
            raise ValidationError("Missing required field: 'id'")

        if content.get('data') is None:
            raise ValidationError("Missing required field: 'data'")

        # 데이터 변환
        processed_at = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
        result = {
            'id': content['id'],
            'data': content['data'],
            'status': 'processed',
            'processed_at': processed_at,
        }

        # DynamoDB에 저장
        table.put_item(Item=result)

        return {
            'statusCode': 200,
            'body': result,
        }

    except ValidationError:
        raise
    except Exception as e:
        print(f"[DEBUG] 원본 에러: {type(e).__name__}: {str(e)}")
        raise ValidationError(f"Unexpected error during transform") from e
