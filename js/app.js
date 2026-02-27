/** App entry point — 3-screen controller (splash → quiz → result) */
(function() {

  // Website URL for QR code
  const SITE_URL = (function() {
    const h = window.location.href.split('?')[0];
    if (h.startsWith('file://') || h.includes('localhost') || h.includes('127.0.0.1')) {
      return 'https://aiguandan.au';
    }
    return h;
  })();

  /** Render a scannable QR code (or fallback decorative pattern) into container */
  function renderMiniQR(container, size) {
    size = size || 72;
    container.innerHTML = '';
    const canvas = document.createElement('canvas');
    canvas.width = size * 2; canvas.height = size * 2;
    canvas.style.width = size + 'px'; canvas.style.height = size + 'px';
    const ctx = canvas.getContext('2d');
    ctx.scale(2, 2);

    if (typeof qrcode !== 'undefined') {
      try {
        const qr = qrcode(0, 'M');
        qr.addData(SITE_URL);
        qr.make();
        const mc = qr.getModuleCount();
        const cell = size / mc;
        ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, size, size);
        ctx.fillStyle = '#000';
        for (let r = 0; r < mc; r++) for (let c = 0; c < mc; c++) {
          if (qr.isDark(r, c)) ctx.fillRect(c * cell, r * cell, cell, cell);
        }
        container.appendChild(canvas);
        return;
      } catch(e) {}
    }

    // Fallback: decorative pattern
    const modules = 21, cellSize = size / modules;
    const matrix = Array(modules).fill(null).map(() => Array(modules).fill(false));
    function drawFinder(r, c) {
      for (let y = 0; y < 7; y++) for (let x = 0; x < 7; x++) {
        const border = y === 0 || y === 6 || x === 0 || x === 6;
        const inner = y >= 2 && y <= 4 && x >= 2 && x <= 4;
        matrix[r + y][c + x] = border || inner;
      }
    }
    drawFinder(0, 0); drawFinder(0, modules - 7); drawFinder(modules - 7, 0);
    for (let i = 8; i < modules - 8; i++) { matrix[6][i] = i % 2 === 0; matrix[i][6] = i % 2 === 0; }
    let hash = 0;
    for (let i = 0; i < SITE_URL.length; i++) hash = ((hash << 5) - hash + SITE_URL.charCodeAt(i)) | 0;
    for (let r = 9; r < modules - 8; r++) for (let c = 9; c < modules - 8; c++) {
      if (c === 6 || r === 6) continue;
      hash = ((hash << 5) - hash + r * 31 + c * 17) | 0;
      matrix[r][c] = (Math.abs(hash) % 3) < 1;
    }
    ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, size, size);
    ctx.fillStyle = '#000';
    for (let r = 0; r < modules; r++) for (let c = 0; c < modules; c++) {
      if (matrix[r][c]) ctx.fillRect(c * cellSize, r * cellSize, cellSize, cellSize);
    }
    container.appendChild(canvas);
  }

  // Expose for quiz.js to use when rendering the result QR
  window._renderMiniQR = renderMiniQR;

  /** Simulated "tested" player count — daily seed + completions */
  function getTestedCount() {
    const d = new Date();
    const daySeed = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
    const base = 8000 + (daySeed % 5000);
    const completions = parseInt(localStorage.getItem('quizCompletions') || '0', 10);
    return base + completions;
  }

  function updateSplash() {
    const el = document.getElementById('splash-tested');
    if (el) el.textContent = getTestedCount().toLocaleString() + ' players tested';
  }

  function showSplash() {
    document.getElementById('quiz-screen')?.classList.remove('active');
    document.getElementById('result-screen')?.classList.remove('active');
    document.getElementById('splash-screen')?.classList.remove('hidden');
    updateSplash();
  }

  window.addEventListener('DOMContentLoaded', () => {
    updateSplash();

    document.getElementById('btn-start')?.addEventListener('click', () => {
      window.Quiz.start();
    });

    document.getElementById('btn-start-ai')?.addEventListener('click', () => {
      window.Quiz.startAI();
    });

    document.getElementById('btn-quiz-next')?.addEventListener('click', () => {
      window.Quiz._next();
    });

    document.getElementById('btn-quiz-close')?.addEventListener('click', () => {
      showSplash();
    });

    document.getElementById('btn-again')?.addEventListener('click', () => {
      showSplash();
    });
  });

})();
