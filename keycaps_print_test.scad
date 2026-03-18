// 验牌测试版 — 各类型各一个, 翻转倒打
use <keycaps_labeled.scad>;

cap_h = 8.0;
cap_base = 18.0;
pitch = 19.05;
cap_gap = (pitch - cap_base) / 2;
sp = cap_base + 3;  // 间距大一点好取

// 翻转1U
module flip_1u() {
    translate([0, cap_base, cap_h])
        rotate([180, 0, 0])
            children();
}

// 翻转2×2
module flip_2x2() {
    w = 2 * pitch - 2 * cap_gap;
    translate([0, w, cap_h])
        rotate([180, 0, 0])
            children();
}

// 第一排: 4花色代表 A♠ K♥ Q♣ J♦
flip_1u() keycap_card("A", "spade");
translate([sp, 0, 0])     flip_1u() keycap_card("K", "heart");
translate([2*sp, 0, 0])   flip_1u() keycap_card("Q", "club");
translate([3*sp, 0, 0])   flip_1u() keycap_card("J", "diamond");

// 第二排: 数字牌 + 王牌
translate([0, sp, 0])     flip_1u() keycap_card("T", "spade");
translate([sp, sp, 0])    flip_1u() keycap_card("2", "heart");
translate([2*sp, sp, 0])  flip_1u() keycap_joker();  // 大王
translate([3*sp, sp, 0])  flip_1u() keycap_joker();  // 小王

// 第三排: 出牌大键 (验证同高)
translate([0, 2*sp + 5, 0])
    flip_2x2() keycap_action("我要验牌");
