import boto3
import base64
import difflib
import os
import time
from datetime import datetime, timezone, timedelta

INSTANCE_ID = os.environ['INSTANCE_ID']
PARAMETER_NAME = '/gj2026/event/app-py'
APP_FILE = '/home/ec2-user/app.py'
SERVICE_NAME = 'gj2026-app'
LOG_GROUP = '/gj2026/event/recovery'
LOG_STREAM = 'recovery-log'

def run_command(ssm, commands):
    res = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName='AWS-RunShellScript',
        Parameters={'commands': commands}
    )
    time.sleep(1)
    return ssm.get_command_invocation(
        CommandId=res['Command']['CommandId'],
        InstanceId=INSTANCE_ID
    )['StandardOutputContent'].strip()

def put_log(logs, message):
    try:
        logs.create_log_group(logGroupName=LOG_GROUP)
    except logs.exceptions.ResourceAlreadyExistsException:
        pass
    try:
        logs.create_log_stream(logGroupName=LOG_GROUP, logStreamName=LOG_STREAM)
    except logs.exceptions.ResourceAlreadyExistsException:
        pass
    logs.put_log_events(
        logGroupName=LOG_GROUP,
        logStreamName=LOG_STREAM,
        logEvents=[{
            'timestamp': int(time.time() * 1000),
            'message': message
        }]
    )

def lambda_handler(event, context):
    ssm = boto3.client('ssm', region_name='ap-northeast-2')
    logs = boto3.client('logs', region_name='ap-northeast-2')
    KST = timezone(timedelta(hours=9))
    now_kst = datetime.now(KST).strftime('%Y-%m-%d %H:%M:%S KST')

    # 1. 프로세스 다운 확인
    count = int(run_command(ssm, ["ps aux | grep '[p]ython3.*app.py' | wc -l"]))
    if count > 0:
        return {'statusCode': 200, 'body': '프로세스 정상, 복구 불필요'}

    # 2. 현재 파일 및 백업 확보
    current_content = run_command(ssm, [f'cat {APP_FILE}'])
    backup_content = ssm.get_parameter(Name=PARAMETER_NAME)['Parameter']['Value']

    # 3. diff 생성
    diff = list(difflib.unified_diff(
        backup_content.splitlines(keepends=True),
        current_content.splitlines(keepends=True),
        fromfile='백업 (정상 버전)',
        tofile='현재 파일 (장애 버전)'
    ))
    diff_text = ''.join(diff) if diff else '(변경 없음)'

    # 4. 파일 복원 및 서비스 재시작
    encoded = base64.b64encode(backup_content.encode()).decode()
    run_command(ssm, [
        f'echo {encoded} | base64 -d > {APP_FILE}',
        f'sudo systemctl restart {SERVICE_NAME}'
    ])

    # 5. /gj2026/event/recovery 로그 기록
    message = f"""[장애 감지] 복구 대상: app
원인: app 프로세스 다운
수정된 내용:
{diff_text}
복구 내용: Parameter Store에서 파일 복원 + 서비스 재시작 완료
복구 완료 시각: {now_kst}"""

    put_log(logs, message)
    return {'statusCode': 200, 'body': '복구 완료'}
