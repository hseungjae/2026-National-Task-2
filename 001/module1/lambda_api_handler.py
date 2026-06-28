import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('wsc2026-api-storage')


def lambda_handler(event, context):
    """
    POST /items  - DynamoDB에 아이템 생성
      Request : {"id": "...", "name": "...", "team": "..."}
      Response: {"message": "Item created successfully", "id": "..."}

    GET /items?id=... - DynamoDB에서 아이템 조회
      Response: {"id": "...", "name": "...", "team": "..."}

    호출 방식:
      - API Gateway (Lambda Proxy Integration): event에 'httpMethod' 키 존재
      - Lambda 직접 호출 (채점용): event에 'method' 키 존재
    """

    # API Gateway 또는 Lambda 직접 호출 모두 지원
    is_apigw = 'httpMethod' in event
    http_method = event.get('httpMethod') or event.get('method', '')

    # ── POST: 아이템 생성 ──────────────────────────────────────────
    if http_method == 'POST':
        # API Gateway는 body가 JSON 문자열, 직접 호출은 dict
        raw_body = event.get('body') if is_apigw else event
        if raw_body is None:
            return _response(400, {'message': 'Request body is required'}, is_apigw)
        if isinstance(raw_body, str):
            raw_body = json.loads(raw_body)

        # 필수 필드 검증
        for field in ('id', 'name', 'team'):
            if field not in raw_body:
                return _response(400, {'message': f'Missing required field: {field}'}, is_apigw)

        item = {
            'id':   raw_body['id'],
            'name': raw_body['name'],
            'team': raw_body['team'],
        }
        table.put_item(Item=item)

        return _response(200, {
            'message': 'Item created successfully',
            'id': raw_body['id'],
        }, is_apigw)

    # ── GET: 아이템 조회 ───────────────────────────────────────────
    elif http_method == 'GET':
        # API Gateway는 queryStringParameters, 직접 호출은 'id' 키
        if is_apigw:
            params = event.get('queryStringParameters') or {}
            item_id = params.get('id')
        else:
            item_id = event.get('id')

        if not item_id:
            return _response(400, {'message': 'Missing query parameter: id'}, is_apigw)

        response = table.get_item(Key={'id': item_id})
        item = response.get('Item')

        if item is None:
            return _response(404, {'message': f'Item not found: {item_id}'}, is_apigw)

        return _response(200, item, is_apigw)

    # ── 지원하지 않는 메서드 ────────────────────────────────────────
    return _response(405, {'message': f'Method not allowed: {http_method}'}, is_apigw)


def _response(status_code: int, body: dict, is_apigw: bool):
    """
    API Gateway 호출이면 statusCode/headers/body 형식,
    Lambda 직접 호출이면 body dict를 그대로 반환.
    """
    if is_apigw:
        return {
            'statusCode': status_code,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(body),
        }
    # Lambda 직접 호출(채점): dict 그대로 반환
    return body
