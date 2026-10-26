#!/usr/bin/env bash
# Argo CD 웹 화면을 https://localhost:8443 으로 연다 (Ctrl+C 로 닫기)
set -euo pipefail

PASSWORD="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"
echo "주소     : https://localhost:8443  (인증서 경고는 '계속' 눌러요)"
echo "아이디   : admin"
echo "비밀번호 : ${PASSWORD:-(초기 비밀번호를 못 찾았어요. 이미 바꿨다면 바꾼 비밀번호)}"
echo
kubectl -n argocd port-forward svc/argocd-server 8443:443
