# k3s CI/CD 테스트

코드를 push 하면 **GitHub Actions(CI) → GHCR 이미지 → Argo CD(CD) → WSL 의 k3s** 로 자동 배포되는지 확인하는 연습용 프로젝트. 모두 무료.

```
내 PC (WSL)                         GitHub
───────────                         ──────
git push ─────────────────────────▶ Actions : 검사 → 빌드 → 이미지(GHCR)
                                            → k8s/kustomization.yaml 태그 커밋
Argo CD (k3s 안) ◀── 3분마다 확인 ── 저장소
   └▶ 새 이미지로 파드 교체 (무중단)
```

PC 쪽에서 GitHub 을 가져오는 방식이라 공유기 · 방화벽 설정이 필요 없다.

## 폴더

| 경로 | 내용 |
|---|---|
| `index.html`, `src/` | Vite 프론트 (버전 · 커밋 · 응답한 파드를 3초마다 보여 줌) |
| `server.js` | 빌드 결과를 보여 주는 서버 + `/api/health`, `/api/info` |
| `Dockerfile` | 2단계 빌드 이미지 |
| `.github/workflows/ci-cd.yml` | CI(검사 · 빌드 · 실행 확인) + CD(이미지 올리기 · 태그 커밋) |
| `k8s/` | 배포 YAML (Deployment 2개 파드, Service, Ingress, Kustomize) |
| `argocd/application.yaml` | Argo CD 에 이 저장소를 등록하는 파일 |
| `scripts/` | k3s · Argo CD 설치, 화면 열기 |

## 처음 한 번

1. GitHub 에서 **공개** 저장소 `k3s-cicd-test` 를 빈 상태로 만든다 (README 없이)
2. 연결하고 push
   ```bash
   git remote add origin https://RYOOKWONHWAN@github.com/RYOOKWONHWAN/k3s-cicd-test.git
   git add . && git commit -m "first commit" && git push -u origin main
   ```
3. Actions 가 끝나면 GitHub 프로필 → Packages → `k3s-cicd-test` → Package settings 에서 **Public** 인지 확인 (비공개면 k3s 가 이미지를 못 받는다)
4. WSL 에 설치
   ```bash
   bash scripts/setup-k3s.sh      # sudo 비밀번호를 물어요
   bash scripts/setup-argocd.sh
   ```

## 확인

```bash
kubectl -n cicd-test get pods        # 파드 2개 Running
bash scripts/open-app.sh             # 앱 → http://localhost:8090
bash scripts/argocd-ui.sh            # Argo CD → https://localhost:8443
```
WSL 안에서는 `curl http://cicd.localhost` 로도 열린다 (Ingress).

## 배포 테스트

1. `package.json` 의 `version` 을 올리거나 `index.html` 문구를 고친다
2. commit · push
3. Actions 초록불 → `deploy: sha-xxxxxxx [skip ci]` 커밋이 자동으로 생김
4. 3분 안에 앱 화면의 버전 · 커밋 · 파드 이름이 바뀐다 (급하면 Argo CD 화면에서 Refresh)

해 볼 만한 것 : 파드 지우기(`kubectl -n cicd-test delete pod <이름>`) → 저절로 다시 생김, `kubectl -n cicd-test scale deploy/cicd-test-app --replicas=5` → Argo CD 가 2개로 되돌림(selfHeal).

## 로컬 개발

```bash
npm install
npm run dev        # Vite 개발 서버
npm run build && npm start   # http://localhost:8080
```

## 끄기 · 지우기

```bash
sudo systemctl stop k3s          # 잠깐 끄기 (다시 켜기 : start)
/usr/local/bin/k3s-uninstall.sh  # 완전히 지우기
```
