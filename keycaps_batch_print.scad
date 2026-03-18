// ============================================================
//  掼蛋键帽 — 批量打印版 (全部翻转倒打)
//  part=1 黑色: ♠26 + 小王×2 + 过牌
//  part=2 红色: ♥26 + 大王×2 + 出牌
//  part=3 白色: ♣26
//  part=4 黄色: ♦26 + 模式
// ============================================================

use <keycaps_labeled.scad>;

cap_h    = 8.0;
cap_base = 18.0;
pitch    = 19.05;
cap_gap  = (pitch - cap_base) / 2;
sp       = cap_base + 1.5;   // 1U间距 19.5mm

RANKS = ["2","A","K","Q","J","T","9","8","7","6","5","4","3"];

// --- 翻转模块 ---
module flip_1u() {
    translate([0, cap_base, cap_h])
        rotate([180, 0, 0])
            children();
}

module flip_2x2() {
    w = 2 * pitch - 2 * cap_gap;
    translate([0, w, cap_h])
        rotate([180, 0, 0])
            children();
}

// --- 一个花色26个 (13×2排) ---
module suit_batch_flip(suit) {
    for (i = [0:12])
        translate([i * sp, 0, 0])
            flip_1u() keycap_card(RANKS[i], suit);
    for (i = [0:12])
        translate([i * sp, sp, 0])
            flip_1u() keycap_card(RANKS[i], suit);
}

// === 渲染控制 ===
part = 1;

// --- 批次1: 黑色 ♠26 + 小王×2 + 过牌 ---
if (part == 1) {
    suit_batch_flip("spade");
    // 小王×2 (第3排)
    translate([0, sp * 2 + 3, 0])
        flip_1u() keycap_joker();
    translate([sp, sp * 2 + 3, 0])
        flip_1u() keycap_joker();
    // 过牌 (第3排右侧)
    translate([sp * 3, sp * 2 + 3, 0])
        flip_2x2() keycap_action("过牌");
}

// --- 批次2: 红色 ♥26 + 大王×2 + 出牌 ---
if (part == 2) {
    suit_batch_flip("heart");
    // 大王×2 (第3排)
    translate([0, sp * 2 + 3, 0])
        flip_1u() keycap_joker();
    translate([sp, sp * 2 + 3, 0])
        flip_1u() keycap_joker();
    // 出牌 (第3排右侧)
    translate([sp * 3, sp * 2 + 3, 0])
        flip_2x2() keycap_action("出牌");
}

// --- 批次3: 白色 ♣26 ---
if (part == 3) {
    suit_batch_flip("club");
}

// --- 批次4: 黄色 ♦26 + 模式 ---
if (part == 4) {
    suit_batch_flip("diamond");
    // 模式 (第3排)
    translate([0, sp * 2 + 3, 0])
        flip_2x2() keycap_action("模式");
}
