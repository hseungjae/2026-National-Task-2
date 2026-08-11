#!/bin/bash
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export REGION=ap-northeast-1
export REPO=$(aws ecr describe-repositories --repository-names o11y-app --region $REGION --query 'repositories[0].repositoryUri' --output text)

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

docker build -t o11y-app .
docker tag o11y-app:latest ${REPO}:latest
docker push ${REPO}:latest