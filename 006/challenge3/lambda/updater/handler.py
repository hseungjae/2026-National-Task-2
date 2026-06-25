import boto3
import os
import time

ssm = boto3.client('ssm')

INSTANCE_ID = os.environ['INSTANCE_ID']
APP_PARAM = '/gj2026/event/app-py'
APP_PATH = '/home/ec2-user/app.py'


def run_command(commands):
    res = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName='AWS-RunShellScript',
        Parameters={'commands': commands}
    )
    command_id = res['Command']['CommandId']
    time.sleep(2)
    for _ in range(15):
        result = ssm.get_command_invocation(CommandId=command_id, InstanceId=INSTANCE_ID)
        if result['Status'] in ['Success', 'Failed', 'TimedOut', 'Cancelled']:
            return result
        time.sleep(2)
    return result


def is_healthy(retries=3, interval=5):
    for _ in range(retries):
        time.sleep(interval)
        result = run_command(['curl -sf http://127.0.0.1:8080/health || echo FAIL'])
        if 'FAIL' in result['StandardOutputContent']:
            return False
    return True


def get_file(path):
    return run_command([f'cat {path}'])['StandardOutputContent']


def get_param(name):
    return ssm.get_parameter(Name=name)['Parameter']['Value']


def update_param(name, value):
    ssm.put_parameter(Name=name, Value=value, Type='String', Overwrite=True)


def lambda_handler(event, context):
    if not is_healthy(retries=3, interval=5):
        print('Health check failed — skip update')
        return {'statusCode': 200, 'body': 'skip'}

    current_app = get_file(APP_PATH)
    if current_app.strip() == get_param(APP_PARAM).strip():
        print('Files match backup — skip')
        return {'statusCode': 200, 'body': 'skip'}

    update_param(APP_PARAM, current_app)
    print('app.py updated in Parameter Store')
    return {'statusCode': 200, 'body': 'updated'}
