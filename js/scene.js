/** scene.js — Guandan visual table + card renderer */
(function () {
  'use strict';

  var RED_SUITS = ['♥', '♦'];

  function parseCard(raw) {
    raw = (raw || '').trim()
      .replace(/黑桃/g,'♠').replace(/红心/g,'♥')
      .replace(/方块/g,'♦').replace(/梅花/g,'♣');
    if (raw === '大王' || raw === '大鬼') return { type: 'bj' };
    if (raw === '小王' || raw === '小鬼') return { type: 'sj' };
    var isLevel = raw.indexOf('*') !== -1;
    var clean = raw.replace(/\*/g, '');
    var suit = '', rank = clean;
    var m = clean.match(/[♠♥♦♣]/);
    if (m) { suit = m[0]; rank = clean.replace(suit, ''); }
    var cls = isLevel ? 'lvl' : RED_SUITS.indexOf(suit) !== -1 ? 'red' : 'blk';
    return { type: 'normal', rank: rank, suit: suit, cls: cls };
  }

  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }

  function makeCard(raw, size) {
    var c = parseCard(raw);
    var d;
    if (c.type === 'bj') {
      d = el('div', 'sc-card sc-card--bj' + (size === 'lg' ? ' sc-card--lg' : ''));
      d.appendChild(el('span', null, '大')); d.appendChild(el('span', null, '王'));
    } else if (c.type === 'sj') {
      d = el('div', 'sc-card sc-card--sj' + (size === 'lg' ? ' sc-card--lg' : ''));
      d.appendChild(el('span', null, '小')); d.appendChild(el('span', null, '王'));
    } else {
      d = el('div', 'sc-card sc-card--' + c.cls + (size === 'lg' ? ' sc-card--lg' : ''));
      d.appendChild(el('span', 'sc-card__rank', c.rank));
      d.appendChild(el('span', 'sc-card__suit', c.suit));
    }
    return d;
  }

  function makeBacks(n) {
    n = parseInt(n) || 0;
    var wrap = el('div', 'sc-backs');
    var shown = Math.min(Math.max(n, 1), 4);
    for (var i = 0; i < shown; i++) {
      var b = el('div', 'sc-back');
      b.style.left = (i * 7) + 'px';
      wrap.appendChild(b);
    }
    wrap.appendChild(el('div', 'sc-backs__count', n + '张'));
    return wrap;
  }

  function makePlayedCards(cards) {
    var wrap = el('div', 'sc-play');
    cards.forEach(function (c) { wrap.appendChild(makeCard(c)); });
    return wrap;
  }

  // ── Main render ────────────────────────────────────────────────────────────

  function renderScene(scene, container) {
    if (!scene || typeof scene !== 'object') {
      container.style.display = 'none';
      return;
    }
    container.style.display = '';
    container.innerHTML = '';

    var tp = scene.table_play && scene.table_play.length > 0 ? (scene.table_player || '') : '';
    var hasPlay = scene.table_play && scene.table_play.length > 0;

    var tbl = el('div', 'sc-table');

    // ── Partner row ──
    var partnerWrap = el('div', 'sc-pos sc-pos--top' + (tp === 'partner' ? ' sc-pos--active' : ''));
    partnerWrap.appendChild(el('div', 'sc-pos__label', '对家'));
    if (tp === 'partner' && hasPlay) {
      partnerWrap.appendChild(makePlayedCards(scene.table_play));
    }
    partnerWrap.appendChild(makeBacks(scene.partner_cards != null ? scene.partner_cards : 8));
    tbl.appendChild(partnerWrap);

    // ── Mid row ──
    var mid = el('div', 'sc-mid');

    // Left opp
    var leftWrap = el('div', 'sc-pos sc-pos--side' + (tp === 'left_opp' ? ' sc-pos--active' : ''));
    leftWrap.appendChild(el('div', 'sc-pos__label', '左家'));
    if (tp === 'left_opp' && hasPlay) {
      leftWrap.appendChild(makePlayedCards(scene.table_play));
    }
    leftWrap.appendChild(makeBacks(scene.left_opp_cards != null ? scene.left_opp_cards : 10));
    mid.appendChild(leftWrap);

    // Center — only hint + level badge (no cards here)
    var ctr = el('div', 'sc-center');
    var hintText = !hasPlay ? '轮到你首出' : (tp === 'hero' ? '你出的牌，等待应对' : null);
    if (hintText) ctr.appendChild(el('div', 'sc-hint', hintText));
    if (scene.level) ctr.appendChild(el('div', 'sc-level-badge', '级牌 ' + scene.level));
    mid.appendChild(ctr);

    // Right opp
    var rightWrap = el('div', 'sc-pos sc-pos--side' + (tp === 'right_opp' ? ' sc-pos--active' : ''));
    rightWrap.appendChild(el('div', 'sc-pos__label', '右家'));
    if (tp === 'right_opp' && hasPlay) {
      rightWrap.appendChild(makePlayedCards(scene.table_play));
    }
    rightWrap.appendChild(makeBacks(scene.right_opp_cards != null ? scene.right_opp_cards : 10));
    mid.appendChild(rightWrap);

    tbl.appendChild(mid);

    // Hero played (table_player = hero)
    if (tp === 'hero' && hasPlay) {
      var heroPlay = el('div', 'sc-hero-play');
      heroPlay.appendChild(makePlayedCards(scene.table_play));
      tbl.appendChild(heroPlay);
    }

    // ── Divider ──
    tbl.appendChild(el('div', 'sc-divider'));

    // ── Hero hand ──
    var hero = el('div', 'sc-hero');
    hero.appendChild(el('div', 'sc-pos__label', '你的手牌'));
    var hand = el('div', 'sc-hand');
    (scene.hero_hand || []).forEach(function (c) { hand.appendChild(makeCard(c, 'lg')); });
    hero.appendChild(hand);
    tbl.appendChild(hero);

    container.appendChild(tbl);
  }

  window.SceneRenderer = { renderScene: renderScene };
})();
