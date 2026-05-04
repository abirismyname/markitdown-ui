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
  function updateMetaThemeColor(theme) {
    var lightColor = '#f0f4ff';
    var darkColor = '#0a0e15';
    var metas = document.querySelectorAll('meta[name="theme-color"]');
    if (!metas.length) return;

    if (theme === 'auto') {
      // Restore the original media-aware pair.
      metas.forEach(function (m) {
        var media = m.getAttribute('data-original-media');
        if (media) m.setAttribute('media', media);
      });
    } else {
      var color = theme === 'dark' ? darkColor : lightColor;
      metas.forEach(function (m) {
        if (!m.hasAttribute('data-original-media') && m.hasAttribute('media')) {
          m.setAttribute('data-original-media', m.getAttribute('media'));
        }
        m.removeAttribute('media');
        m.setAttribute('content', color);
      });
    }
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
