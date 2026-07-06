import json
import base64
import io
import re
import os
from datetime import datetime, timezone, timedelta
from urllib.parse import parse_qs

import boto3
from PIL import Image

s3 = boto3.client('s3', region_name='us-east-1')

BUCKET_NAME = '${bucket_name}'
KST = timezone(timedelta(hours=9))


def lambda_handler(event, context):
    record = event['Records'][0]['cf']
    request = record['request']
    response = record['response']

    if response.get('status') != '200':
        return response

    qs = parse_qs(request.get('querystring', ''))
    try:
        w = int(qs.get('w', ['1920'])[0])
        h = int(qs.get('h', ['1080'])[0])
    except (ValueError, IndexError):
        return response

    device_type = qs.get('type', ['desktop'])[0]

    uri = request['uri']
    object_key = uri.lstrip('/')

    try:
        obj = s3.get_object(Bucket=BUCKET_NAME, Key=object_key)
        original_bytes = obj['Body'].read()
    except Exception as e:
        print(f"[ERROR] S3 get_object: {e}")
        return response

    try:
        img = Image.open(io.BytesIO(original_bytes))
        resized = img.resize((w, h), Image.LANCZOS)
        out_buf = io.BytesIO()
        resized.save(out_buf, format='PNG')
        resized_bytes = out_buf.getvalue()
    except Exception as e:
        print(f"[ERROR] Resize: {e}")
        return response

    filename = os.path.basename(object_key)
    stem = re.sub(r'\.[^.]+$', '', filename)

    ts = datetime.now(KST).strftime('%Y%m%d_%H%M%S')
    resized_key = f"resized/{device_type}_{stem}_{ts}.png"

    try:
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=resized_key,
            Body=resized_bytes,
            ContentType='image/png'
        )
    except Exception as e:
        print(f"[ERROR] S3 put_object: {e}")

    response['status'] = '200'
    response['statusDescription'] = 'OK'
    response['body'] = base64.b64encode(resized_bytes).decode('utf-8')
    response['bodyEncoding'] = 'base64'
    response['headers']['content-type'] = [{
        'key': 'Content-Type', 'value': 'image/png'
    }]
    response['headers']['content-length'] = [{
        'key': 'Content-Length', 'value': str(len(resized_bytes))
    }]

    return response
