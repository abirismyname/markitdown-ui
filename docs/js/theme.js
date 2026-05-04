/* MarkyMarkdown — theme switcher
   Stores user preference in localStorage under "mm-theme":
     "auto"  — follow system (default)
     "light" — force light
     "dark"  — force dark
*/
(function () {
  var STORAGE_KEY = 'mm-theme';
  var VALID = ['auto', 'light', 'dark'];

  function getSaved() {
    try {
      var v = localStorage.getItem(STORAGE_KEY);
      return VALID.indexOf(v) !== -1 ? v : 'auto';
    } catch (_) {
      return 'auto';
    }
  }

  function applyTheme(theme) {
    if (theme === 'auto') {
      document.documentElement.removeAttribute('data-theme');
    } else {
      document.documentElement.setAttribute('data-theme', theme);
    }
    updateMetaThemeColor(theme);
  }

  // Keep iOS Safari / Android Chrome browser chrome in sync with manual overrides.
  // Color values are read from the existing <meta name="theme-color"> tags so
  // they remain defined in a single place (the HTML head).
  function updateMetaThemeColor(theme) {
    var metas = document.querySelectorAll('meta[name="theme-color"]');
    if (!metas.length) return;

    // Snapshot original media + content on first invocation so we can restore
    // the media-aware pair when the user switches back to Auto.
    metas.forEach(function (m) {
      if (!m.hasAttribute('data-original-content')) {
        m.setAttribute('data-original-content', m.getAttribute('content') || '');
      }
      if (!m.hasAttribute('data-original-media') && m.hasAttribute('media')) {
        m.setAttribute('data-original-media', m.getAttribute('media'));
      }
    });

    if (theme === 'auto') {
      metas.forEach(function (m) {
        var media = m.getAttribute('data-original-media');
        var content = m.getAttribute('data-original-content');
        if (media) m.setAttribute('media', media);
        if (content) m.setAttribute('content', content);
      });
      return;
    }

    // Pick the color from whichever original meta matches the chosen theme.
    var wantMedia = theme === 'dark'
      ? '(prefers-color-scheme: dark)'
      : '(prefers-color-scheme: light)';
    var picked = null;
    metas.forEach(function (m) {
      if (m.getAttribute('data-original-media') === wantMedia) {
        picked = m.getAttribute('data-original-content');
      }
    });
    if (!picked) return;

    metas.forEach(function (m) {
      m.removeAttribute('media');
      m.setAttribute('content', picked);
    });
  }

  function syncSwitch(theme) {
    var buttons = document.querySelectorAll('.theme-switch button[data-theme-value]');
    buttons.forEach(function (btn) {
      var match = btn.getAttribute('data-theme-value') === theme;
      btn.setAttribute('aria-checked', match ? 'true' : 'false');
      btn.setAttribute('tabindex', match ? '0' : '-1');
    });
  }

  function setTheme(theme) {
    if (VALID.indexOf(theme) === -1) theme = 'auto';
    try { localStorage.setItem(STORAGE_KEY, theme); } catch (_) {}
    applyTheme(theme);
    syncSwitch(theme);
  }

  // Initial sync (the inline pre-paint script already applied data-theme).
  document.addEventListener('DOMContentLoaded', function () {
    var current = getSaved();
    syncSwitch(current);
    updateMetaThemeColor(current);

    var buttons = document.querySelectorAll('.theme-switch button[data-theme-value]');
    buttons.forEach(function (btn) {
      btn.addEventListener('click', function () {
        setTheme(btn.getAttribute('data-theme-value'));
      });
    });
  });
})();
