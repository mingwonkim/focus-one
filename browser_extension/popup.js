// browser_extension/popup.js
const DEFAULTS = {
  enabled: true,
  videoLock: true,
  blockForwardSeek: true,
  blockDuplicates: true,
  duplicateSites: ['youtube.com'],
};

const $ = (id) => document.getElementById(id);
const savedLabel = $('saved');
let savedTimer = null;

function showSaved() {
  savedLabel.style.visibility = 'visible';
  clearTimeout(savedTimer);
  savedTimer = setTimeout(() => {
    savedLabel.style.visibility = 'hidden';
  }, 1200);
}

async function load() {
  const s = await chrome.storage.sync.get(DEFAULTS);
  $('enabled').checked = s.enabled;
  $('videoLock').checked = s.videoLock;
  $('blockForwardSeek').checked = s.blockForwardSeek;
  $('blockDuplicates').checked = s.blockDuplicates;
  $('duplicateSites').value = s.duplicateSites.join('\n');
}

function bind() {
  for (const id of ['enabled', 'videoLock', 'blockForwardSeek', 'blockDuplicates']) {
    $(id).addEventListener('change', async (e) => {
      await chrome.storage.sync.set({ [id]: e.target.checked });
      showSaved();
    });
  }

  $('duplicateSites').addEventListener('input', async (e) => {
    const sites = e.target.value
      .split('\n')
      .map((line) => line.trim().toLowerCase().replace(/^www\./, ''))
      .filter((line) => line.length > 0);
    await chrome.storage.sync.set({ duplicateSites: sites });
    showSaved();
  });
}

load().then(bind);
