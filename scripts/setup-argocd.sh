#!/usr/bin/env bash
# k3s 에 Argo CD 를 설치하고, 이 저장소를 지켜보게 등록한다
set -euo pipefail
cd "$(dirname "$0")/.."

ARGOCD_VERSION="${ARGOCD_VERSION:-stable}"

# git remote 주소에서 사용자 이름(https://이름@github.com)을 빼고 .git 을 붙인다
REPO_URL="$(git remote get-url origin 2>/dev/null || true)"
if [ -z "$REPO_URL" ]; then
  echo "git remote origin 이 없어요. GitHub 저장소를 만들고 git remote add origin 을 먼저 해 주세요" >&2
  exit 1
fi
REPO_URL="$(echo "$REPO_URL" | sed -E 's|https://[^@/]+@|https://|; s|\.git$||').git"
echo "== 지켜볼 저장소 : $REPO_URL"

echo "== Argo CD 설치 ($ARGOCD_VERSION)"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
# CRD 가 커서 server-side apply 로 적용한다
kubectl apply -n argocd --server-side --force-conflicts \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

echo "== Argo CD 가 뜰 때까지 기다리는 중 (몇 분 걸려요)"
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

echo "== 앱 등록"
sed "s|REPO_URL|${REPO_URL}|" argocd/application.yaml | kubectl apply -f -

echo
echo "끝. Argo CD 가 3분 안에 저장소를 읽고 배포해요."
echo "  배포 확인 : kubectl -n cicd-test get pods"
echo "  앱 화면   : http://cicd.localhost"
echo "  Argo 화면 : bash scripts/argocd-ui.sh"
