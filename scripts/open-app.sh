#!/usr/bin/env bash
# 윈도우 브라우저에서 http://localhost:8090 으로 앱을 연다 (Ctrl+C 로 닫기)
# http://cicd.localhost 가 윈도우에서 안 열릴 때 쓴다 (WSL 네트워크 설정에 따라 다름)
set -euo pipefail
echo "주소 : http://localhost:8090"
kubectl -n cicd-test port-forward svc/cicd-test-app 8090:80
