import json, os, boto3
from decimal import Decimal
from dotenv import load_dotenv

load_dotenv(dotenv_path="/opt/python/.env")

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.getenv("tableName"))


class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return int(o) if o % 1 == 0 else float(o)
        return super().default(o)


def lambda_handler(event, context):
    if event["httpMethod"] == "GET":
        if event.get("queryStringParameters") is not None:
            year = event["queryStringParameters"].get("admission_year")
            name = event["queryStringParameters"].get("student_name")
            if year is not None and name is not None:
                if year.isdigit() and len(year) == 4 and isinstance(name, str):
                    response = table.get_item(Key={"admission_year": int(year), "student_name": name}).get("Item", None)
                    if response is not None:
                        return {
                            'statusCode': 200,
                            'body': json.dumps(response, cls=DecimalEncoder, ensure_ascii=False)
                        }
                    else:
                        return {
                            'statusCode': 404,
                            'body': "찾을 수 없습니다."
                        }
                else:
                    return {
                        'statusCode': 400,
                        'body': "올바르게 입력해주세요."
                    }
            else:
                return {
                    'statusCode': 400,
                    'body': "필수 요청값을 입력해주세요."
                }
        else:
            return {
                'statusCode': 200,
                'body': json.dumps(table.scan().get("Items", []), cls=DecimalEncoder, ensure_ascii=False)
            }
    elif event["httpMethod"] == "POST":
        if event["body"] is not None:
            body = json.loads(event["body"])
            if body.get("admission_year") is not None and body.get("student_name") is not None:
                if isinstance(body["admission_year"], int) and len(str(body["admission_year"])) == 4 and isinstance(body["student_name"], str):
                    response = table.put_item(Item=body)["ResponseMetadata"]["HTTPStatusCode"]
                    if response == 200:
                        return {
                            'statusCode': response,
                            'body': json.dumps(body, cls=DecimalEncoder, ensure_ascii=False)
                        }
                    else:
                        return {
                            'statusCode': response,
                            'body': "문제가 발생했습니다. 다시시도해주세요."
                        }
                else:
                    return {
                        'statusCode': 400,
                        'body': "올바르게 입력해주세요."
                    }
        return {
            'statusCode': 400,
            'body': "필수 요청값을 입력해주세요."
        }
    else:
        return {
            'statusCode': 405,
            'body': "잘못된 요청입니다."
        }