import './style.css';

const FIELDS = ['version', 'commit', 'buildTime', 'pod', 'startedAt'];
const seenPods = new Map(); // 파드 이름 → 버전

function formatTime(value) {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString('ko-KR');
}

function renderPods() {
  const list = document.getElementById('pods');
  list.replaceChildren(
    ...[...seenPods].map(([pod, version]) => {
      const li = document.createElement('li');
      li.textContent = `${pod} (v${version})`;
      return li;
    }),
  );
}

async function refresh() {
  const status = document.getElementById('status');
  try {
    const res = await fetch('/api/info', { cache: 'no-store' });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const info = await res.json();
    FIELDS.forEach((key) => {
      const value = key.endsWith('Time') || key === 'startedAt' ? formatTime(info[key]) : info[key];
      document.getElementById(key).textContent = value ?? '-';
    });
    seenPods.set(info.pod, info.version);
    renderPods();
    status.textContent = `마지막 확인 ${new Date().toLocaleTimeString('ko-KR')}`;
    status.classList.remove('error');
  } catch (err) {
    // 배포 중에 잠깐 끊길 수 있어서 다음 확인 때 다시 시도한다
    status.textContent = `서버 응답 없음 (${err.message}), 다시 시도 중...`;
    status.classList.add('error');
  }
}

refresh();
setInterval(refresh, 3000);
