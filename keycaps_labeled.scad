// ============================================================
//  掼蛋键盘 — 带标识键帽 (扑克牌风格)
//
//  左上角: 点数 (大号粗体)
//  右下角: 花色图案 (几何图形)
//
//  底部: 圆柱boss + 十字插槽 (标准MX套入轴柱)
//  凹刻深度0.8mm
//
//  打印: Bambu A1 (256×256mm), 0.2mm层高
// ============================================================

$fn = 40;

// ===== 键帽基础参数 =====
pitch    = 19.05;
cap_base = 18.0;       // 底面边长
cap_top  = 15.5;       // 顶面边长
cap_h    = 8.0;        // 键帽高度
wall_t   = 1.5;        // 壁厚
cap_gap  = (pitch - cap_base) / 2;

// ===== MX十字插槽 — 对照Outemu规格图 =====
//  轴柱十字: 臂长4.00±0.05, 臂宽1.10±0.03, 柱高3.70±0.20
//  FDM打印孔会缩小~0.1mm, 所以设计值要加补偿
cross_l    = 4.10;     // 十字臂长 (轴4.00 + 0.10mm间隙)
cross_w    = 1.25;     // 十字臂宽 (轴1.10 + 0.15mm, 打印后~1.15, 实际间隙0.05)
cross_d    = 3.90;     // 十字槽深 (轴柱高3.70, 留0.2mm底)
boss_r     = 2.8;      // 圆柱boss半径 (直径5.6mm, 包住轴柱)
// boss高度必须顶到键帽内腔天花板, 否则按不到轴!
boss_h_1u  = cap_h - wall_t;    // 1U键帽: 8.0-1.5 = 6.5mm
boss_h_2x2 = cap_h - wall_t;         // 2×2键帽: 与1U同高 8.0-1.5 = 6.5mm

// ===== 标识参数 =====
deboss     = 0.8;      // 文字凹刻深度 (封板后不怕桥接)
suit_deboss = 0.8;     // 花色凹刻深度
rank_size  = 7.0;      // 点数文字大小
suit_size  = 6.0;      // 花色图案大小
rank_font  = "Arial:style=Bold";

// ===== 派生 =====
taper      = (cap_base - cap_top) / 2;  // 1.25mm

// ===== 点数列表 =====
RANKS = ["2","A","K","Q","J","T","9","8","7","6","5","4","3"];


// ==========================================================
//  花色几何图形 (2D)
// ==========================================================

// ♠ 黑桃
module spade_2d(s) {
    r = s * 0.24;
    union() {
        translate([-r, s*0.05]) circle(r=r);
        translate([r, s*0.05]) circle(r=r);
        polygon([[0, s*0.48], [-s*0.48, -s*0.05], [s*0.48, -s*0.05]]);
        translate([-s*0.07, -s*0.45])
            square([s*0.14, s*0.35]);
        translate([-s*0.18, -s*0.45]) circle(r=s*0.1);
        translate([s*0.18, -s*0.45]) circle(r=s*0.1);
    }
}

// ♥ 红心 (放大比例, 确保FDM可见)
module heart_2d(s) {
    r = s * 0.30;   // 0.25→0.30, 圆更大更明显
    union() {
        translate([-r*0.85, s*0.12]) circle(r=r);
        translate([r*0.85, s*0.12]) circle(r=r);
        polygon([[-s*0.50, s*0.10], [s*0.50, s*0.10], [0, -s*0.52]]);
    }
}

// ♣ 梅花
module club_2d(s) {
    r = s * 0.21;
    union() {
        translate([0, s*0.18]) circle(r=r);
        translate([-s*0.2, -s*0.08]) circle(r=r);
        translate([s*0.2, -s*0.08]) circle(r=r);
        translate([-s*0.06, -s*0.45])
            square([s*0.12, s*0.35]);
        translate([-s*0.15, -s*0.45]) circle(r=s*0.08);
        translate([s*0.15, -s*0.45]) circle(r=s*0.08);
    }
}

// ♦ 方块
module diamond_2d(s) {
    polygon([
        [0, s*0.48],
        [s*0.33, 0],
        [0, -s*0.48],
        [-s*0.33, 0]
    ]);
}

// 五角星 2D
module star_2d(r) {
    ri = r * 0.38;
    points = [for (i = [0:9])
        let(angle = 90 + i * 36,
            radius = (i % 2 == 0) ? r : ri)
        [radius * cos(angle), radius * sin(angle)]
    ];
    polygon(points);
}


// ==========================================================
//  键帽外壳 (梯形体, 内部中空)
// ==========================================================
module keycap_shell() {
    difference() {
        // 外壳
        hull() {
            cube([cap_base, cap_base, 0.01]);
            translate([taper, taper, cap_h])
                cube([cap_top, cap_top, 0.01]);
        }
        // 内腔掏空
        hull() {
            translate([wall_t, wall_t, -0.01])
                cube([cap_base-2*wall_t, cap_base-2*wall_t, 0.01]);
            translate([taper+wall_t, taper+wall_t, cap_h-wall_t])
                cube([cap_top-2*wall_t, cap_top-2*wall_t, 0.01]);
        }
    }
}


// ==========================================================
//  MX十字插座 (圆柱boss + 十字槽)
//  从键帽内腔底部向下伸出, 套在轴的十字柱上
// ==========================================================
module mx_stem(h=0) {
    // h=0时自动用1U高度
    bh = (h > 0) ? h : boss_h_1u;
    rib = 1.2;  // 肋厚
    // 肋条起始高度: 必须高于轴体外壳顶部
    // 轴柱3.9mm + 按键行程4mm = 需要至少留出 ~4.5mm 空间
    rib_z = 4.5;  // 肋从4.5mm处开始, 不干涉轴体

    union() {
        // 圆柱boss (从底部到顶, 这个不影响—轴柱插在里面)
        difference() {
            translate([cap_base/2, cap_base/2, 0])
                cylinder(r=boss_r, h=bh);
            // 十字槽 (只在底部)
            translate([cap_base/2, cap_base/2, -0.01]) {
                translate([-cross_l/2, -cross_w/2, 0])
                    cube([cross_l, cross_w, cross_d + 0.01]);
                translate([-cross_w/2, -cross_l/2, 0])
                    cube([cross_w, cross_l, cross_d + 0.01]);
            }
        }

        // 十字内肋 — 连接boss到四壁, 只在上半部分
        // 从rib_z开始到顶, 避开下方轴体行程空间
        // 横肋
        translate([wall_t, cap_base/2 - rib/2, rib_z])
            cube([cap_base - 2*wall_t, rib, bh - rib_z]);
        // 竖肋
        translate([cap_base/2 - rib/2, wall_t, rib_z])
            cube([rib, cap_base - 2*wall_t, bh - rib_z]);

        // 顶部封板 — 1mm厚实心板, 彻底消除桥接镂空
        translate([wall_t, wall_t, bh - 1])
            cube([cap_base - 2*wall_t, cap_base - 2*wall_t, 1]);
    }
}


// ==========================================================
//  完整键帽基础 (外壳 + 十字插座)
// ==========================================================
module keycap_body() {
    keycap_shell();
    mx_stem();
}


// ==========================================================
//  带标识的1U键帽 (扑克牌风格)
//
//    ┌─────────────┐
//    │ A           │  ← 左上角: 点数
//    │             │
//    │             │
//    │           ♠ │  ← 右下角: 花色
//    └─────────────┘
// ==========================================================
module keycap_card(rank, suit) {
    difference() {
        keycap_body();

        // 顶面坐标参考:
        // 左上角 ≈ (taper+1, taper+cap_top-1, cap_h)
        // 右下角 ≈ (taper+cap_top-1, taper+1, cap_h)
        // 中心 = (cap_base/2, cap_base/2, cap_h)

        // --- 左上角: 点数 ---
        translate([taper + cap_top*0.25,
                   taper + cap_top*0.72,
                   cap_h - deboss + 0.01])
            linear_extrude(deboss + 0.1)
                text(rank, size=rank_size,
                     font=rank_font,
                     halign="center", valign="center");

        // --- 右下角: 花色图案 ---
        translate([taper + cap_top*0.75,
                   taper + cap_top*0.28,
                   cap_h - suit_deboss + 0.01])
            linear_extrude(suit_deboss + 0.1) {
                if (suit == "spade")   spade_2d(suit_size);
                if (suit == "heart")   heart_2d(suit_size);
                if (suit == "club")    club_2d(suit_size);
                if (suit == "diamond") diamond_2d(suit_size);
            }
    }
}


// ==========================================================
//  大王/小王 键帽 (纯图案)
//  大王: 大号皇冠 (crown)
//  小王: 小丑帽 (jester hat)
// ==========================================================

// 皇冠 2D (大王)
module crown_2d(s) {
    // 底座横条
    translate([-s*0.45, -s*0.35])
        square([s*0.9, s*0.2]);
    // 5个尖角
    polygon([
        [-s*0.45, -s*0.15],
        [-s*0.45, s*0.05],
        [-s*0.3,  -s*0.05],
        [-s*0.15, s*0.25],
        [0,       -s*0.0],
        [s*0.15,  s*0.25],
        [s*0.3,   -s*0.05],
        [s*0.45,  s*0.05],
        [s*0.45,  -s*0.15],
    ]);
    // 三颗宝石圆点 (尖顶)
    translate([-s*0.3, s*0.05]) circle(r=s*0.06);
    translate([0, s*0.25]) circle(r=s*0.06);
    translate([s*0.3, s*0.05]) circle(r=s*0.06);
}

// 小丑帽 2D (小王)
module jester_2d(s) {
    // 帽身 (弧形)
    translate([-s*0.35, -s*0.35])
        square([s*0.7, s*0.25]);
    // 三个弯角
    // 左角
    hull() {
        translate([-s*0.35, -s*0.1]) circle(r=s*0.06);
        translate([-s*0.45, s*0.3]) circle(r=s*0.08);
    }
    // 中角
    hull() {
        translate([0, -s*0.1]) circle(r=s*0.06);
        translate([0, s*0.4]) circle(r=s*0.08);
    }
    // 右角
    hull() {
        translate([s*0.35, -s*0.1]) circle(r=s*0.06);
        translate([s*0.45, s*0.3]) circle(r=s*0.08);
    }
    // 铃铛 (三个尖端圆球)
    translate([-s*0.45, s*0.3]) circle(r=s*0.1);
    translate([0, s*0.4]) circle(r=s*0.1);
    translate([s*0.45, s*0.3]) circle(r=s*0.1);
}

module keycap_joker() {
    // 大王小王都用小丑帽图案, 靠PLA颜色区分:
    //   大王 = 红色PLA 打印
    //   小王 = 深灰PLA 打印
    difference() {
        keycap_body();

        translate([cap_base/2, cap_base/2, cap_h - suit_deboss + 0.01])
            linear_extrude(suit_deboss + 0.1)
                jester_2d(cap_top * 0.55);
    }
}


// ==========================================================
//  功能键 2×2 (出牌/不要/模式)
// ==========================================================
module keycap_action(label) {
    w = 2 * pitch - 2 * cap_gap;
    w_top = w - 3;
    h = cap_h;        // 与1U同高
    tp = (w - w_top) / 2;
    cn_font = "Microsoft YaHei:style=Bold";

    difference() {
        // 外壳
        union() {
            // 壳体
            difference() {
                hull() {
                    cube([w, w, 0.01]);
                    translate([tp, tp, h]) cube([w_top, w_top, 0.01]);
                }
                hull() {
                    translate([wall_t, wall_t, -0.01])
                        cube([w-2*wall_t, w-2*wall_t, 0.01]);
                    translate([tp+wall_t, tp+wall_t, h-wall_t])
                        cube([w_top-2*wall_t, w_top-2*wall_t, 0.01]);
                }
            }

            // 4个MX十字插座 — 顶到2×2内腔天花板
            for (dx=[0,1]) for (dy=[0,1]) {
                sx = pitch/2 - cap_gap + dx*pitch;
                sy = pitch/2 - cap_gap + dy*pitch;
                translate([sx, sy, 0])
                    difference() {
                        cylinder(r=boss_r, h=boss_h_2x2);
                        translate([0, 0, -0.01]) {
                            translate([-cross_l/2, -cross_w/2, 0])
                                cube([cross_l, cross_w, cross_d+0.02]);
                            translate([-cross_w/2, -cross_l/2, 0])
                                cube([cross_w, cross_l, cross_d+0.02]);
                        }
                    }
            }

            // 内部支撑肋 — 井字形, 充分撑住顶面
            // 从4.5mm高度开始, 避开轴体行程空间
            rib_t = 1.5;
            rib_z2 = 4.5;
            s1 = pitch/2 - cap_gap;       // 第1排boss中心
            s2 = pitch/2 - cap_gap + pitch; // 第2排boss中心

            // 3条横肋 (从rib_z2到顶)
            for (yy = [s1, w/2, s2])
                translate([wall_t + 1, yy - rib_t/2, rib_z2])
                    cube([w - 2*wall_t - 2, rib_t, boss_h_2x2 - rib_z2]);
            // 3条竖肋 (从rib_z2到顶)
            for (xx = [s1, w/2, s2])
                translate([xx - rib_t/2, wall_t + 1, rib_z2])
                    cube([rib_t, w - 2*wall_t - 2, boss_h_2x2 - rib_z2]);
        }

        // 凹刻中文 (横排居中, 支持2字或4字)
        // 顶面中心 = (w/2, w/2, h), 顶面宽 = w_top ≈ 34mm
        n = len(label);
        if (n == 2) {
            translate([w/2 - 7, w/2, h - deboss + 0.01])
                linear_extrude(deboss + 0.1)
                    text(label[0], size=10, font=cn_font,
                         halign="center", valign="center");
            translate([w/2 + 7, w/2, h - deboss + 0.01])
                linear_extrude(deboss + 0.1)
                    text(label[1], size=10, font=cn_font,
                         halign="center", valign="center");
        }
        if (n == 4) {
            // 上排两字, 下排两字
            translate([w/2 - 6, w/2 + 6.5, h - deboss + 0.01])
                linear_extrude(deboss + 0.1)
                    text(label[0], size=9, font=cn_font,
                         halign="center", valign="center");
            translate([w/2 + 6, w/2 + 6.5, h - deboss + 0.01])
                linear_extrude(deboss + 0.1)
                    text(label[1], size=9, font=cn_font,
                         halign="center", valign="center");
            translate([w/2 - 6, w/2 - 6.5, h - deboss + 0.01])
                linear_extrude(deboss + 0.1)
                    text(label[2], size=9, font=cn_font,
                         halign="center", valign="center");
            translate([w/2 + 6, w/2 - 6.5, h - deboss + 0.01])
                linear_extrude(deboss + 0.1)
                    text(label[3], size=9, font=cn_font,
                         halign="center", valign="center");
        }
    }
}


// ==========================================================
//  批量排列 — 一个花色26个键帽 (13点数×2副)
//  13个/行 × 19.5mm间距 = 253.5mm
// ==========================================================
sp = cap_base + 1.5;  // 19.5mm 间距

module suit_batch(suit) {
    for (i = [0:12])
        translate([i * sp, 0, 0])
            keycap_card(RANKS[i], suit);
    for (i = [0:12])
        translate([i * sp, sp, 0])
            keycap_card(RANKS[i], suit);
}


// ==========================================================
//  渲染控制
// ==========================================================
//  0  = 预览: 样品键帽
//  1  = ♠ 黑桃 26个 (深灰PLA)
//  2  = ♥ 红心 26个 (红色PLA)
//  3  = ♣ 梅花 26个 (绿色PLA)
//  4  = ♦ 方块 26个 (橙色PLA)
//  5  = 大王×2 (红色PLA, 小丑帽图案)
//  6  = 小王×2 (深灰PLA, 小丑帽图案)
//  7  = 出牌键 (红色PLA, 2×2)
//  8  = Pass键 (深灰PLA, 2×2)
//  9  = 模式键 (绿色PLA, 2×2)
//  10 = 全色预览
part = 0;


if (part == 0) {
    // 样品: 4花色 A/K/Q/J
    keycap_card("A", "spade");
    translate([sp, 0, 0])   keycap_card("K", "heart");
    translate([2*sp, 0, 0]) keycap_card("Q", "club");
    translate([3*sp, 0, 0]) keycap_card("J", "diamond");

    // 王牌
    translate([5*sp, 0, 0]) keycap_joker();
    translate([6*sp, 0, 0]) keycap_joker();

    // 功能键
    translate([0, sp*2, 0]) keycap_action("出牌");
    translate([2.2*pitch, sp*2, 0]) keycap_action("过牌");
    translate([4.4*pitch, sp*2, 0]) keycap_action("模式");
}

if (part == 1) suit_batch("spade");
if (part == 2) suit_batch("heart");
if (part == 3) suit_batch("club");
if (part == 4) suit_batch("diamond");

if (part == 5) {
    keycap_joker();
    translate([sp, 0, 0]) keycap_joker();
}
if (part == 6) {
    keycap_joker();
    translate([sp, 0, 0]) keycap_joker();
}

if (part == 7) keycap_action("出牌");
if (part == 8) keycap_action("过牌");
if (part == 9) keycap_action("模式");

if (part == 10) {
    color([0.3, 0.3, 0.35])  suit_batch("spade");
    color([0.9, 0.2, 0.2])   translate([0, sp*3, 0]) suit_batch("heart");
    color([0.2, 0.7, 0.3])   translate([0, sp*6, 0]) suit_batch("club");
    color([0.95, 0.6, 0.1])  translate([0, sp*9, 0]) suit_batch("diamond");
}
