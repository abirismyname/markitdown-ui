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
    updateThemedImages(theme);
  }

  // Resolve the effective color scheme (light/dark) for a given preference,
  // consulting the system when the user has chosen "auto".
  function resolveScheme(theme) {
    if (theme === 'light' || theme === 'dark') return theme;
    try {
      return window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark'
        : 'light';
    } catch (_) {
      return 'light';
    }
  }

  // Swap any <img> with data-light-src / data-dark-src to match the active
  // theme. This complements the <picture> media-query fallback so manual
  // theme-switcher changes are reflected immediately.
  //
  // Note: a matching <source> inside <picture> takes precedence over the
  // <img>'s src, so once JS is in control we strip those <source> children
  // (the inline media-query fallback only matters for no-JS visitors).
  function updateThemedImages(theme) {
    var scheme = resolveScheme(theme);
    var attr = scheme === 'dark' ? 'data-dark-src' : 'data-light-src';
    var imgs = document.querySelectorAll('img[data-light-src][data-dark-src]');
    imgs.forEach(function (img) {
      var picture = img.parentNode;
      if (picture && picture.tagName === 'PICTURE') {
        var sources = picture.querySelectorAll('source');
        sources.forEach(function (s) { picture.removeChild(s); });
      }
      var next = img.getAttribute(attr);
      if (next && img.getAttribute('src') !== next) {
        img.setAttribute('src', next);
      }
    });
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
    updateThemedImages(current);

    var buttons = document.querySelectorAll('.theme-switch button[data-theme-value]');
    buttons.forEach(function (btn) {
      btn.addEventListener('click', function () {
        setTheme(btn.getAttribute('data-theme-value'));
      });
    });

    // When the user is on "auto", follow live system color-scheme changes so
    // themed images flip without a page reload.
    try {
      var mql = window.matchMedia('(prefers-color-scheme: dark)');
      var onChange = function () {
        if (getSaved() === 'auto') updateThemedImages('auto');
      };
      if (mql.addEventListener) {
        mql.addEventListener('change', onChange);
      } else if (mql.addListener) {
        mql.addListener(onChange);
      }
    } catch (_) {}
  });
})();
