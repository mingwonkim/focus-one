// browser_extension/youtube-lock.js
// 유튜브 페이지 안에서 동작하는 콘텐츠 스크립트.
//
// 1) 영상 잠금: 영상 재생을 시작하면 그 영상이 끝날 때까지
//    다른 영상으로 이동 불가 (링크 클릭, 다음 버튼, 주소창 이동 전부 방어)
// 2) 앞으로 감기 차단: 이미 본 지점(maxPlayed)보다 앞으로는 시킹 불가.
//    뒤로 돌려 다시 보는 것은 허용. (화살표 키/L 키 시킹도 동일하게 잡힘)
//
// 상시 동작하며, 팝업 설정에서 기능별로 끌 수 있다.

(() => {
  const DEFAULTS = {
    enabled: true,
    videoLock: true,
    blockForwardSeek: true,
  };

  let settings = { ...DEFAULTS };
  chrome.storage.sync.get(DEFAULTS).then((s) => {
    settings = s;
  });
  chrome.storage.onChanged.addListener((changes) => {
    for (const key of Object.keys(changes)) {
      settings[key] = changes[key].newValue;
    }
  });

  let lockedVideoId = null; // 잠긴 영상 ID
  let lockedUrl = null;     // 되돌아갈 URL
  let maxPlayed = 0;        // 실제로 시청한 최대 지점 (초)
  let currentVideo = null;  // 현재 <video> 엘리먼트

  // /watch?v=... 또는 /shorts/... 에서 영상 ID 추출
  function videoIdFrom(url) {
    try {
      const u = new URL(url, location.origin);
      if (!u.hostname.includes('youtube.com')) return null;
      if (u.pathname === '/watch') return u.searchParams.get('v');
      const shorts = u.pathname.match(/^\/shorts\/([\w-]+)/);
      if (shorts) return shorts[1];
    } catch {
      /* 무시 */
    }
    return null;
  }

  // ---- 안내 토스트 ----
  let toastTimer = null;
  function toast(message) {
    let el = document.getElementById('focusone-guard-toast');
    if (!el) {
      el = document.createElement('div');
      el.id = 'focusone-guard-toast';
      el.style.cssText = [
        'position:fixed', 'bottom:24px', 'left:50%',
        'transform:translateX(-50%)', 'z-index:2147483647',
        'background:rgba(26,26,26,0.92)', 'color:#fff',
        'padding:10px 16px', 'border-radius:8px',
        'font-size:13px', 'font-family:sans-serif',
        'pointer-events:none', 'transition:opacity 0.2s',
      ].join(';');
      document.documentElement.appendChild(el);
    }
    el.textContent = message;
    el.style.opacity = '1';
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      el.style.opacity = '0';
    }, 2200);
  }

  function unlock() {
    lockedVideoId = null;
    lockedUrl = null;
  }

  // ---- <video> 엘리먼트 감시 및 이벤트 연결 ----
  function attachVideo() {
    const video = document.querySelector('video');
    if (!video || video === currentVideo) return;
    currentVideo = video;
    maxPlayed = 0;

    video.addEventListener('timeupdate', () => {
      if (!video.seeking) {
        maxPlayed = Math.max(maxPlayed, video.currentTime);
      }
      // 끝 3초 전부터는 "다 본 것"으로 간주하고 잠금 해제
      if (
        lockedVideoId &&
        video.duration &&
        video.currentTime >= video.duration - 3
      ) {
        unlock();
      }
    });

    video.addEventListener('ended', unlock);

    // 앞으로 감기 차단 (뒤로는 허용)
    video.addEventListener('seeking', () => {
      if (!settings.enabled || !settings.blockForwardSeek) return;
      if (video.currentTime > maxPlayed + 1.5) {
        video.currentTime = maxPlayed;
        toast('앞으로 감기는 잠겨 있어요. 뒤로 돌리는 건 가능해요.');
      }
    });

    // 재생 시작 → 이 영상을 잠근다
    video.addEventListener('playing', () => {
      if (!settings.enabled || !settings.videoLock) return;
      const id = videoIdFrom(location.href);
      if (id && !lockedVideoId) {
        lockedVideoId = id;
        lockedUrl = location.href;
      }
    });
  }

  // ---- 다른 영상으로의 클릭 차단 (캡처 단계에서 먼저 가로챔) ----
  document.addEventListener(
    'click',
    (event) => {
      if (!settings.enabled || !settings.videoLock || !lockedVideoId) return;

      for (const el of event.composedPath()) {
        // 다른 영상으로 가는 링크
        if (el instanceof HTMLAnchorElement && el.href) {
          const id = videoIdFrom(el.href);
          if (id && id !== lockedVideoId) {
            event.preventDefault();
            event.stopPropagation();
            toast('지금 영상을 끝까지 본 뒤에 이동할 수 있어요.');
            return;
          }
        }
        // 플레이어의 "다음 영상" 버튼
        if (
          el instanceof HTMLElement &&
          el.classList &&
          el.classList.contains('ytp-next-button')
        ) {
          event.preventDefault();
          event.stopPropagation();
          toast('지금 영상을 끝까지 본 뒤에 이동할 수 있어요.');
          return;
        }
      }
    },
    true, // 캡처 단계
  );

  // ---- SPA 네비게이션/주소창 이동 방어 ----
  // 유튜브는 페이지 새로고침 없이 주소만 바뀌므로 주기적으로 검사해서,
  // 잠금 중에 다른 영상으로 이동했으면 원래 영상으로 되돌린다.
  setInterval(() => {
    attachVideo();
    if (!settings.enabled || !settings.videoLock || !lockedVideoId) return;
    const id = videoIdFrom(location.href);
    if (id && id !== lockedVideoId && lockedUrl) {
      toast('영상이 끝나기 전에는 이동할 수 없어요.');
      location.replace(lockedUrl);
    }
  }, 800);
})();
