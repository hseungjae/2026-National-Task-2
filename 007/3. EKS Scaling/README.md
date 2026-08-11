1. keda 모듈까지 주석해제 후 terraform apply 

2. `docker/` 폴더와 `scripts` 폴더를 이용해서 이미지를 올려준다.

3. 나머지 k8s 리소스 배포 terraform apply 

*주의사항*
`source kubectl-connect skm-eks-cluster` 명령어가 DNS 오류가 안될 시 아래 명령어를 수행해준다.
```bash
rm -f ~/.kube/config-skm-eks-cluster
```