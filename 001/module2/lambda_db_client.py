import json
import boto3
import pymysql
import os

SECRET_NAME = os.environ.get('SECRET_NAME', 'wsc2026-db-secret')
REGION = os.environ.get('AWS_REGION', 'ap-northeast-1')


def get_db_credentials():
    client = boto3.client('secretsmanager', region_name=REGION)
    response = client.get_secret_value(SecretId=SECRET_NAME)
    return json.loads(response['SecretString'])


def get_connection(creds):
    # Proxy 엔드포인트를 Secrets Manager의 host 필드에서 가져옴
    proxy_host = creds.get('host')
    if not proxy_host:
        raise ValueError("Secrets Manager에 'host' (proxy endpoint) 값이 없습니다.")
    return pymysql.connect(
        host=proxy_host,
        user=creds['username'],
        password=creds['password'],
        database=creds.get('dbname', 'wsc2026'),
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=10,
    )


def lambda_handler(event, context):
    action = event.get('action')
    creds = get_db_credentials()

    if action == 'create':
        username = event['username']
        role = event['role']

        conn = get_connection(creds)
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO users (username, role) VALUES (%s, %s)",
                    (username, role),
                )
            conn.commit()
        finally:
            conn.close()

        return {
            'statusCode': 201,
            'body': json.dumps({'message': f'User {username} created successfully'}),
        }

    elif action == 'read':
        username = event['username']

        conn = get_connection(creds)
        try:
            with conn.cursor() as cursor:
                cursor.execute(
                    "SELECT username, role, created_at FROM users WHERE username = %s",
                    (username,),
                )
                row = cursor.fetchone()
        finally:
            conn.close()

        if row:
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'username': row['username'],
                    'role': row['role'],
                    'created_at': str(row['created_at']),
                }),
            }

        return {
            'statusCode': 404,
            'body': json.dumps({'message': f'User {username} not found'}),
        }

    return {
        'statusCode': 400,
        'body': json.dumps({'message': 'Invalid action. Use "create" or "read"'}),
    }
