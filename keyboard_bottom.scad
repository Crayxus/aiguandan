// ============================================================
//  CRAYXUS Guandan Keyboard — Bottom Cover
//  底盖 — 封闭底座底部, 含脚垫位+螺丝柱+走线槽
// ============================================================

$fn = 60;

// ===== 与底座匹配的参数 =====
base_w     = 310;
base_d     = 185;
wall       = 3.0;
split_x    = base_w / 2;

// ===== 底盖参数 =====
cover_t    = 1.5;      // 盖板厚度
rim_h      = 3.0;      // 内嵌卡边高度
rim_inset  = 1.0;      // 卡边内缩量 (配合底座内壁)

// ===== 脚垫 =====
pad_r      = 8;        // 脚垫直径
pad_h      = 2.0;      // 脚垫凸起 (贴硅胶垫用)
pad_inset  = 20;       // 距边缘

// ===== 螺丝柱 =====
screw_r    = 3.5;      // 螺丝柱外径
screw_hole = 1.4;      // 自攻螺丝孔径 (M2.5)
screw_h    = 8.0;      // 螺丝柱高度
n_screws_w = 3;        // 宽度方向螺丝数
n_screws_d = 2;        // 深度方向螺丝数

// ===== 走线槽 =====
chan_w     = 12;        // 走线槽宽
chan_d     = 60;        // 走线槽长

// ===== 卡扣 (与底座一致) =====
tab_w      = 4.0;
tab_d      = 18.0;
tab_tol    = 0.15;
n_tabs     = 3;

// ==========================================================
module bottom_half(side = "left") {
    is_left = (side == "left");
    hw = base_w / 2;

    difference() {
        union() {
            // 主盖板
            cube([hw, base_d, cover_t]);

            // 内嵌卡边 (伸入底座内壁)
            translate([rim_inset, rim_inset, cover_t])
                difference() {
                    cube([hw - rim_inset * (is_left ? 1 : 1),
                          base_d - 2 * rim_inset,
                          rim_h]);
                    // 掏空内部 (只留边框)
                    translate([wall, wall, -0.1])
                        cube([hw - rim_inset - wall * 2 + (is_left ? 0 : rim_inset),
                              base_d - 2 * rim_inset - wall * 2,
                              rim_h + 0.2]);
                }

            // 螺丝柱
            for (ix = [0 : n_screws_w - 1]) {
                for (iy = [0 : n_screws_d - 1]) {
                    sx = 20 + ix * (hw - 40) / max(n_screws_w - 1, 1);
                    sy = 25 + iy * (base_d - 50) / max(n_screws_d - 1, 1);
                    translate([sx, sy, cover_t])
                        difference() {
                            cylinder(r = screw_r, h = screw_h);
                            translate([0, 0, -0.1])
                                cylinder(r = screw_hole, h = screw_h + 0.2);
                        }
                }
            }

            // 脚垫凸台 (4个角)
            for (px = [pad_inset, hw - pad_inset])
                for (py = [pad_inset, base_d - pad_inset])
                    translate([px, py, -pad_h])
                        cylinder(r = pad_r, h = pad_h);
        }

        // 走线槽 (中央, 从后边缘到中间)
        translate([hw/2 - chan_w/2, base_d - chan_d, -0.1])
            cube([chan_w, chan_d + 1, cover_t + 0.2]);

        // USB开口 (后方中央)
        if (is_left) {
            translate([hw - 12, base_d - wall - 1, -0.1])
                cube([24, wall + 2, cover_t + rim_h + 0.2]);
        }

        // 通风孔 (网格)
        vent_cols = 6;
        vent_rows = 3;
        vent_w = 15;
        vent_h = 3;
        vx_start = hw/2 - (vent_cols * (vent_w + 3)) / 2;
        vy_start = base_d/2 - (vent_rows * (vent_h + 4)) / 2;
        for (vx = [0 : vent_cols - 1])
            for (vy = [0 : vent_rows - 1])
                translate([vx_start + vx * (vent_w + 3),
                           vy_start + vy * (vent_h + 4), -0.1])
                    cube([vent_w, vent_h, cover_t + 0.2]);

        // 切半: 只保留左半或右半
        if (is_left) {
            translate([hw + 0.01, -1, -pad_h - 1])
                cube([hw + 10, base_d + 2, 30]);
        } else {
            // 右半: 镜像X, 先生成左半然后mirror
        }
    }
}

// 右半 = 左半镜像
module bottom_right() {
    translate([base_w/2, 0, 0])
        mirror([1, 0, 0])
            bottom_half("left");
}

// ==========================================================
//  渲染控制
// ==========================================================
part = 0;  // 0=预览, 1=左半, 2=右半

if (part == 0) {
    color([0.2, 0.2, 0.22]) bottom_half("left");
    color([0.2, 0.2, 0.22]) bottom_right();
}
if (part == 1) bottom_half("left");
if (part == 2) bottom_right();
