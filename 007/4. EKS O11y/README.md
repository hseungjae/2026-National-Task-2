1. eks 모듈까지 주석해제 후 terraform apply

2. `docker/` 폴더와 `scripts` 폴더를 이용해서 이미지를 올려준다.

3. 나머지 리소스 배포 terraform apply

4. 로그를 생성해준다.
```bash
curl -s "http://$(aws elbv2 describe-load-balancers --names o11y-app-alb --query 'LoadBalancers[0].DNSName' --output text --region ap-northeast-1)/log?level=info&count=3"
curl -s "http://$(aws elbv2 describe-load-balancers --names o11y-app-alb --query 'LoadBalancers[0].DNSName' --output text --region ap-northeast-1)/log?level=warn&count=3"
curl -s "http://$(aws elbv2 describe-load-balancers --names o11y-app-alb --query 'LoadBalancers[0].DNSName' --output text --region ap-northeast-1)/log?level=error&count=3"

```

*주의사항*
`source kubectl-connect o11y-cluster` 명령어가 DNS 오류가 안될 시 아래 명령어를 수행해준다.
```bash
rm -f ~/.kube/config-o11y-cluster
```