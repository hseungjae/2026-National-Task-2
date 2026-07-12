import json
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

# Lambda warm start reuse - boto3 Connection Reuse
_config = Config(tcp_keepalive=True)
dynamodb = boto3.client('dynamodb', region_name='us-east-1', config=_config)

TABLE_NAME = 'wsc-rest-table'


def lambda_handler(event, context):
    http_method = event.get('httpMethod', '')

    try:
        if http_method == 'POST':
            return _create_user(event)
        elif http_method == 'GET':
            return _get_user(event)
        else:
            return _resp(405, {'message': 'Method not allowed'})
    except Exception:
        return _resp(500, {'message': 'Internal server error'})


def _create_user(event):
    try:
        body = json.loads(event.get('body') or '{}')
    except (json.JSONDecodeError, TypeError):
        return _resp(400, {'message': 'Invalid request body'})

    name = body.get('name')
    age = body.get('age')
    country = body.get('country')

    if name is None or age is None or country is None:
        return _resp(400, {'message': 'Missing required fields'})

    try:
        dynamodb.put_item(
            TableName=TABLE_NAME,
            Item={
                'name':    {'S': str(name)},
                'age':     {'N': str(int(age))},
                'country': {'S': str(country)},
            },
            # Conditional Write - Retry-safe duplicate prevention
            ConditionExpression='attribute_not_exists(#n)',
            ExpressionAttributeNames={'#n': 'name'},
        )
        return _resp(200, {'message': 'User created successfully'})

    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            return _resp(409, {'message': 'User already exists'})
        raise


def _get_user(event):
    params = event.get('queryStringParameters') or {}
    name = params.get('name')

    if not name:
        return _resp(400, {'message': 'Missing required request parameters: [name]'})

    try:
        response = dynamodb.get_item(
            TableName=TABLE_NAME,
            Key={'name': {'S': str(name)}},
        )
    except ClientError:
        raise

    item = response.get('Item')
    if not item:
        return _resp(404, {'message': 'User not found'})

    return _resp(200, {
        'name':    item['name']['S'],
        'country': item['country']['S'],
        'age':     int(item['age']['N']),
    })


def _resp(status_code: int, body: dict) -> dict:
    return {
        'statusCode': status_code,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(body),
    }
