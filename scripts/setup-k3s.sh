#!/usr/bin/env bash
# WSL 에 k3s 를 설치하고 kubectl 이 바로 쓰이게 설정한다 (sudo 비밀번호를 물어요)
set -euo pipefail

if ! command -v k3s >/dev/null 2>&1; then
  echo "== k3s 설치"
  curl -sfL https://get.k3s.io | sudo sh -s - --write-kubeconfig-mode 644
else
  echo "== k3s 가 이미 있어요 ($(k3s --version | head -1))"
fi

echo "== kubectl 설정 (~/.kube/config)"
mkdir -p "$HOME/.kube"
if [ -f "$HOME/.kube/config" ] && ! cmp -s /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"; then
  cp "$HOME/.kube/config" "$HOME/.kube/config.backup-$(date +%Y%m%d-%H%M%S)"
  echo "   기존 설정을 백업했어요"
fi
cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

echo "== 노드가 준비될 때까지 기다리는 중"
kubectl wait --for=condition=Ready node --all --timeout=120s
kubectl get nodes -o wide
echo "끝. 다음 : bash scripts/setup-argocd.sh"
