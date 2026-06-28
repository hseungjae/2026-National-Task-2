# Challenge 1 - 수동 작업 가이드

## 1. Terraform Apply

```bash
cd terraform/2026-National-Task-2/05/challenge1
terraform init
terraform apply -auto-approve
```

생성되는 리소스:
- VPC, 서브넷 (ap-northeast-2)
- EKS 클러스터 (wsc-scaling-cluster, v1.35)
- SQS 큐 (wsc-scaling-sqs)
- IAM Role (node, karpenter, keda, bastion)
- Bastion EC2 (wsc-scaling-bastion)
- Helm: Karpenter, KEDA
- Kubernetes: Namespace, Deployment, ServiceAccount

SSH 키 파일은 `ec2/wsc-scaling-bastion-key.pem`에 저장됨.

---

## 2. Bastion 접속

```bash
# Bastion 퍼블릭 IP 확인
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=wsc-scaling-bastion" \
  --region ap-northeast-2 \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text

# SSH 접속
ssh -i terraform/2026-National-Task-2/05/challenge1/ec2/wsc-scaling-bastion-key.pem \
    ec2-user@<BASTION_PUBLIC_IP>
```

---

## 3. apply-manifests.sh 스크립트 실행 (Bastion에서)

```bash
# 로컬에서 스크립트 복사
scp -i terraform/2026-National-Task-2/05/challenge1/ec2/wsc-scaling-bastion-key.pem \
    terraform/2026-National-Task-2/05/challenge1/script/apply-manifests.sh \
    ec2-user@<BASTION_PUBLIC_IP>:~/apply-manifests.sh

# Bastion에서 실행
chmod +x ~/apply-manifests.sh
./apply-manifests.sh
```

스크립트가 처리하는 작업:
1. EKS kubeconfig 업데이트
2. EC2NodeClass 생성 (Karpenter)
3. NodePool 생성 (Karpenter)
4. ScaledObject 생성 (KEDA - SQS 기반 오토스케일링)

---

## 4. 확인 명령어

```bash
# Karpenter NodePool 상태
kubectl get nodepool

# KEDA ScaledObject 상태
kubectl get scaledobject -n wsc-scaling

# Deployment 상태
kubectl get deployment -n wsc-scaling

# Pod 상태
kubectl get pods -n wsc-scaling
```

---

## 5. 참고

- ScaledObject `ACTIVE=False`는 SQS 메시지가 없을 때 정상 (최소 2개 replica 유지)
- SQS 메시지 전송 시 자동으로 Pod 스케일아웃
