/** Quiz controller — G.Quiz / window.Quiz */
(function() {

  class QuizController {
    constructor() {
      this.currentIdx = 0;
      this.score = 0;
      this.correctCount = 0;
      this.answers = [];
      this.startTime = null;
      this._selectedOpt = null;
      // AI 模式
      this.mode = 'classic';          // 'classic' | 'ai'
      this.aiQuestions = [];          // 已生成的 AI 题目缓存
      this._usedCategories = [];      // 已用分类，避免重复
      this._prefetchPromise = null;   // 预加载中的 Promise
    }

    /** ── 辅助：当前题库长度 ── */
    _quizLength() {
      return this.mode === 'ai' ? 10 : QUIZ_DATA.length;
    }

    /** ── 辅助：获取当前题目 ── */
    _getQuestion(idx) {
      return this.mode === 'ai' ? this.aiQuestions[idx] : QUIZ_DATA[idx];
    }

    /** ── 经典模式：重置并显示第一题 ── */
    start() {
      this.mode = 'classic';
      this._resetState();
      this._switchToQuizScreen();
      this._showQuestion(0);
    }

    /** ── AI 模式：生成全新题目集 ── */
    startAI() {
      this.mode = 'ai';
      this.aiQuestions = [];
      this._usedCategories = [];
      this._prefetchPromise = null;
      this._resetState();
      this._switchToQuizScreen();
      // 第一题：显示加载，然后展示
      this._loadAndShowQuestion(0);
      // 同时预加载第2题
      this._prefetchQuestion(1);
    }

    _resetState() {
      this.currentIdx = 0;
      this.score = 0;
      this.correctCount = 0;
      this.answers = [];
      this.startTime = Date.now();
      this._selectedOpt = null;
    }

    _switchToQuizScreen() {
      document.getElementById('splash-screen')?.classList.add('hidden');
      document.getElementById('result-screen')?.classList.remove('active');
      const qs = document.getElementById('quiz-screen');
      if (qs) qs.classList.add('active');
    }

    /** ── AI 模式：获取第 idx 题（先查缓存，再请求）── */
    async _loadAndShowQuestion(idx) {
      if (this.aiQuestions[idx]) {
        this._showQuestion(idx);
        return;
      }
      // 显示加载中
      this._setAiLoading(true);
      try {
        // 如果恰好有预加载进行中，等它完成
        if (this._prefetchPromise) {
          await this._prefetchPromise;
          this._prefetchPromise = null;
        }
        // 仍未加载到（预加载是下一题），自己请求
        if (!this.aiQuestions[idx]) {
          await this._fetchQuestion(idx);
        }
      } catch(e) {
        console.error('AI出题失败', e);
        this._setAiLoading(false);
        alert('AI出题失败：' + (e.message || e) + '\n\n请检查：\n1. server.py 是否启动\n2. KIMI_API_KEY 是否配置');
        return;
      }
      this._setAiLoading(false);
      this._showQuestion(idx);
    }

    /** ── 预加载第 idx 题（不阻塞UI）── */
    _prefetchQuestion(idx) {
      if (idx >= this._quizLength() || this.aiQuestions[idx]) return;
      this._prefetchPromise = this._fetchQuestion(idx).catch(() => {});
    }

    /** ── 调用后端接口生成题目 ── */
    async _fetchQuestion(idx) {
      const resp = await fetch('/api/ai-question', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          question_index: idx,
          used_categories: this._usedCategories,
        }),
      });
      const data = await resp.json();
      if (!data.ok) throw new Error(data.error || '接口返回错误');
      this.aiQuestions[idx] = data.question;
      if (data.question.category) {
        this._usedCategories.push(data.question.category);
      }
      return data.question;
    }

    /** ── 显示/隐藏加载遮罩 ── */
    _setAiLoading(show) {
      let overlay = document.getElementById('ai-loading-overlay');
      if (!overlay) {
        overlay = document.createElement('div');
        overlay.id = 'ai-loading-overlay';
        overlay.innerHTML = `
          <div class="ai-loading-inner">
            <div class="ai-loading-spinner"></div>
            <div class="ai-loading-text">AI 正在出题…</div>
          </div>`;
        overlay.style.cssText = `
          position:fixed;inset:0;background:rgba(8,12,22,.85);
          display:flex;align-items:center;justify-content:center;
          z-index:9999;backdrop-filter:blur(4px);`;
        document.body.appendChild(overlay);
      }
      overlay.style.display = show ? 'flex' : 'none';
    }

    /** Render question at index idx */
    _showQuestion(idx) {
      const q = this._getQuestion(idx);
      this._selectedOpt = null;

      // Progress bar
      const fill = document.getElementById('quiz-progress-fill');
      const label = document.getElementById('quiz-progress-label');
      if (fill) fill.style.width = (idx / this._quizLength() * 100) + '%';
      if (label) label.textContent = (idx + 1) + ' / ' + this._quizLength();

      // Category tag
      const catEl = document.getElementById('quiz-cat');
      if (catEl) catEl.textContent = q.category;

      // Difficulty dots
      const dotsEl = document.getElementById('quiz-dots');
      if (dotsEl) {
        dotsEl.innerHTML = '';
        for (let i = 1; i <= 5; i++) {
          const dot = document.createElement('span');
          dot.textContent = i <= q.difficulty ? '●' : '○';
          dot.className = i <= q.difficulty ? 'dot-filled' : 'dot-empty';
          dotsEl.appendChild(dot);
        }
      }

      // Scene (visual card table — AI mode only)
      const sceneEl = document.getElementById('quiz-scene');
      if (sceneEl && window.SceneRenderer) {
        window.SceneRenderer.renderScene(q.scene || null, sceneEl);
      }

      // Question text
      const qEl = document.getElementById('quiz-question');
      if (qEl) {
        qEl.textContent = q.text;
        qEl.classList.toggle('has-scene', !!(q.scene));
      }

      // Option buttons
      const optsEl = document.getElementById('quiz-options');
      if (optsEl) {
        optsEl.innerHTML = '';
        q.options.forEach((opt, i) => {
          const btn = document.createElement('button');
          btn.className = 'quiz-opt-btn';
          btn.textContent = opt;
          btn.addEventListener('click', () => this._onSelect(i));
          optsEl.appendChild(btn);
        });
      }

      // Hide feedback panel
      const feedbackEl = document.getElementById('quiz-feedback');
      if (feedbackEl) feedbackEl.classList.add('hidden');
    }

    /** Handle option selection */
    _onSelect(optIdx) {
      if (this._selectedOpt !== null) return; // already answered
      this._selectedOpt = optIdx;

      const q = this._getQuestion(this.currentIdx);
      const isCorrect = optIdx === q.answer;

      if (isCorrect) {
        this.score += q.points;
        this.correctCount++;
      }

      this.answers.push({ idx: this.currentIdx, selected: optIdx, correct: isCorrect });

      // Color the buttons green/red
      const btns = document.querySelectorAll('.quiz-opt-btn');
      btns.forEach((btn, i) => {
        btn.disabled = true;
        if (i === q.answer) {
          btn.classList.add('correct');
        } else if (i === optIdx && !isCorrect) {
          btn.classList.add('wrong');
        }
      });

      // Show explanation
      const explainEl = document.getElementById('quiz-explain');
      if (explainEl) {
        const raw = q.explanation || '';
        const short = raw.length > 60 ? raw.slice(0, 58) + '…' : raw;
        explainEl.textContent = (isCorrect ? '✓ ' : '✗ ') + short;
        explainEl.className = 'quiz-explain ' + (isCorrect ? 'correct' : 'wrong');
      }

      // Show feedback area
      const feedbackEl = document.getElementById('quiz-feedback');
      if (feedbackEl) feedbackEl.classList.remove('hidden');

      // Update next-button label
      const nextBtn = document.getElementById('btn-quiz-next');
      if (nextBtn) {
        nextBtn.textContent = this.currentIdx < this._quizLength() - 1 ? '下一题 →' : '查看结果 →';
      }
    }

    /** Advance to next question or finish */
    _next() {
      this.currentIdx++;
      if (this.currentIdx >= this._quizLength()) {
        this._finish();
      } else if (this.mode === 'ai') {
        // AI模式：异步加载，同时预加载下下题
        this._loadAndShowQuestion(this.currentIdx);
        this._prefetchQuestion(this.currentIdx + 1);
      } else {
        this._showQuestion(this.currentIdx);
      }
    }

    /** Calculate result and switch to result screen */
    _finish() {
      // Increment completion counter
      const prev = parseInt(localStorage.getItem('quizCompletions') || '0', 10);
      localStorage.setItem('quizCompletions', prev + 1);

      const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
      const minutes = Math.floor(elapsed / 60);
      const seconds = elapsed % 60;
      const timeStr = minutes + ':' + String(seconds).padStart(2, '0');

      document.getElementById('quiz-screen')?.classList.remove('active');
      document.getElementById('result-screen')?.classList.add('active');

      this._renderResult(timeStr);
    }

    /** Map score to tier object */
    _getTier(score) {
      if (score >= 92) return { name: '宗师', icon: '🔥', label: '传奇', color: '#ff6b35' };
      if (score >= 83) return { name: '大师', icon: '⭐', label: '钻石', color: '#b9f2ff' };
      if (score >= 71) return { name: '高手', icon: '💎', label: '铂金', color: '#e5e4e2' };
      if (score >= 55) return { name: '进阶', icon: '🏅', label: '黄金', color: '#ffc800' };
      if (score >= 30) return { name: '入门', icon: '🥈', label: '白银', color: '#c0c0c0' };
      return { name: '新手', icon: '🥉', label: '青铜', color: '#cd7f32' };
    }

    /** Interpolate percentile from score */
    _getPercentile(score) {
      const table = [[0, 10], [30, 25], [55, 50], [71, 75], [83, 90], [92, 98], [100, 99]];
      for (let i = 0; i < table.length - 1; i++) {
        const [s0, p0] = table[i];
        const [s1, p1] = table[i + 1];
        if (score >= s0 && score <= s1) {
          const t = (score - s0) / (s1 - s0);
          return Math.round(p0 + t * (p1 - p0));
        }
      }
      return 99;
    }

    /** Populate result screen with quiz outcome */
    _renderResult(timeStr) {
      const win = this.score >= 55;
      const tier = this._getTier(this.score);
      const percentile = this._getPercentile(this.score);

      // Hero banner
      const heroEl = document.getElementById('result-hero');
      if (heroEl) heroEl.className = 'result-hero ' + (win ? 'win' : 'lose');

      const titleEl = document.getElementById('result-title');
      if (titleEl) {
        titleEl.textContent = win ? '优秀' : '继续加油';
        titleEl.className = 'rout-title ' + (win ? 'win' : 'lose');
      }

      const subtitleEl = document.getElementById('result-subtitle');
      if (subtitleEl) subtitleEl.textContent = tier.label + '段';

      const deltaEl = document.getElementById('result-elo-change');
      if (deltaEl) {
        deltaEl.textContent = '超越 ' + percentile + '% 玩家';
        deltaEl.className = 'rout-delta ' + (win ? 'pos' : 'neg');
      }

      // Tier icon
      const tierIconEl = document.getElementById('result-tier-icon');
      if (tierIconEl) tierIconEl.textContent = tier.icon;

      // Score as main number
      const skillIndexEl = document.getElementById('result-skill-index');
      if (skillIndexEl) {
        skillIndexEl.textContent = this.score;
        skillIndexEl.className = 'result-skill-index';
      }

      // Stars: 5 stars scaled from 0-100
      const starsEl = document.getElementById('result-stars');
      if (starsEl) {
        starsEl.innerHTML = '';
        const starsFilled = Math.round(this.score / 20); // 0-5
        for (let i = 0; i < 5; i++) {
          const star = document.createElement('span');
          star.className = 'star-icon ' + (i < starsFilled ? 'filled' : 'empty');
          star.textContent = '★';
          if (i < starsFilled) star.style.color = tier.color;
          starsEl.appendChild(star);
        }
      }

      const skillLvlEl = document.getElementById('result-skill-level');
      if (skillLvlEl) skillLvlEl.textContent = '实力等级 · ' + tier.name + ' · ' + tier.label;

      // Hide game-specific elements
      const legendRankEl = document.getElementById('result-legend-rank');
      if (legendRankEl) legendRankEl.style.display = 'none';
      const lockEl = document.getElementById('result-elo-lock');
      if (lockEl) lockEl.style.display = 'none';

      // Quiz detail line
      const detailEl = document.getElementById('result-quiz-detail');
      if (detailEl) {
        const modeTag = this.mode === 'ai' ? ' · AI出题' : '';
        detailEl.textContent = this.correctCount + ' / ' + this._quizLength() + ' 答对 · 用时 ' + timeStr + modeTag;
      }

      // QR code
      const qrBox = document.getElementById('result-qr-box');
      if (qrBox && typeof window._renderMiniQR === 'function') {
        window._renderMiniQR(qrBox, 130);
      }

      // Scroll result to top
      const scroll = document.querySelector('.result-scroll');
      if (scroll) scroll.scrollTop = 0;
    }
  }

  window.Quiz = new QuizController();

})();
