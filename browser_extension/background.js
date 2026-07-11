// browser_extension/background.js
// 같은 사이트의 중복 탭/창 차단.
// 등록된 사이트(기본: youtube.com)가 이미 열려 있으면,
// 새 탭/새 창으로 같은 사이트를 열 때 새 쪽을 닫고 기존 탭으로 이동시킨다.
// → "창 하나 더 띄워서 유튜브 들어가기" 우회를 원천 차단.

const DEFAULTS = {
  enabled: true,          // 확장 전체 on/off
  blockDuplicates: true,  // 중복 탭/창 차단 on/off
  duplicateSites: ['youtube.com'],
};

function getSettings() {
  return chrome.storage.sync.get(DEFAULTS);
}

function hostnameOf(url) {
  try {
    return new URL(url).hostname.replace(/^www\./, '');
  } catch {
    return null;
  }
}

// host가 site와 같거나 그 서브도메인인지
function matchesSite(host, site) {
  return host === site || host.endsWith('.' + site);
}

async function checkDuplicate(tabId, url) {
  const settings = await getSettings();
  if (!settings.enabled || !settings.blockDuplicates) return;

  const host = hostnameOf(url);
  if (!host) return;

  const site = settings.duplicateSites.find((s) => matchesSite(host, s));
  if (!site) return;

  // 같은 사이트가 열린 다른 탭 찾기 (모든 창 포함)
  const allTabs = await chrome.tabs.query({});
  const existing = allTabs.filter((t) => {
    if (t.id === tabId || !t.url) return false;
    const h = hostnameOf(t.url);
    return h && matchesSite(h, site);
  });

  if (existing.length === 0) return;

  // 새 탭을 닫고 기존 탭으로 포커스 이동
  try {
    await chrome.tabs.remove(tabId);
  } catch {
    // 이미 닫혔으면 무시
  }
  try {
    await chrome.tabs.update(existing[0].id, { active: true });
    await chrome.windows.update(existing[0].windowId, { focused: true });
  } catch {
    // 포커스 실패는 무시
  }
}

// 탭이 등록 사이트로 이동(새 탭 포함)하는 순간 검사
chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.url) {
    checkDuplicate(tabId, changeInfo.url);
  }
});
