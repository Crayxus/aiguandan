// ============================================================
//  掼蛋专用键盘 — 定位板 (Plate)
//  就像普通机械键盘的金属板, 只是我们的layout是15×8
//  轴从上方卡入14×14mm方孔, 卡扣弹开锁定
//
//  适配: Bambu A1 (256×256mm), Cherry MX兼容3PIN轴
//  打印: PLA, 0.2mm层高, 100%填充, Brim 5mm
// ============================================================

$fn = 30;

// ===== 布局 =====
pitch      = 19.05;     // 标准MX键距
hole       = 14.2;      // MX方孔 14mm + 0.2mm打印公差
plate_t    = 1.5;       // 板厚 1.5mm (MX标准, 和照片里的金属板一样)
border     = 3.0;       // 边框宽度
cols       = 15;
rows       = 8;
split_col  = 8;         // 左半0-7列, 右半8-14列

// ===== 拼接卡扣 =====
tab_w      = 4.0;
tab_d      = 15.0;
tab_h_tol  = 0.15;
n_tabs     = 4;

// ===== 派生 =====
total_w    = cols * pitch;    // 285.75mm
total_d    = rows * pitch;    // 152.4mm

// ==========================================================
//  定位板半片
// ==========================================================
module plate_half(side="left") {
    col_start = (side == "left") ? 0 : split_col;
    col_end   = (side == "left") ? split_col : cols;
    n_cols    = col_end - col_start;

    pw = n_cols * pitch + border;  // 一侧有边框
    pd = total_d + 2 * border;    // 上下都有边框
    x_off = (side == "left") ? border : 0;

    difference() {
        union() {
            // 主板体: 一整块1.5mm平板
            cube([pw, pd, plate_t]);

            // 左半右边凸出卡扣
            if (side == "left") {
                tab_spacing = (total_d - n_tabs * tab_d) / (n_tabs + 1);
                for (i = [0 : n_tabs-1]) {
                    ty = border + tab_spacing * (i+1) + tab_d * i;
                    translate([pw, ty, 0])
                        cube([tab_w, tab_d, plate_t]);
                }
            }
        }

        // 14×14mm 方孔, 穿透整板
        for (r = [0 : rows-1]) {
            for (c = [col_start : col_end-1]) {
                local_c = c - col_start;
                cx = x_off + local_c * pitch + pitch/2;
                cy = border + r * pitch + pitch/2;
                translate([cx - hole/2, cy - hole/2, -0.01])
                    cube([hole, hole, plate_t + 0.02]);
            }
        }

        // 右半左边凹入卡槽
        if (side == "right") {
            tab_spacing = (total_d - n_tabs * tab_d) / (n_tabs + 1);
            slot_w = tab_w + tab_h_tol * 2;
            slot_d = tab_d + tab_h_tol * 2;
            for (i = [0 : n_tabs-1]) {
                ty = border + tab_spacing * (i+1) + tab_d * i - tab_h_tol;
                translate([-0.01, ty, -0.01])
                    cube([slot_w + 0.01, slot_d, plate_t + 0.02]);
            }
        }
    }
}

// ==========================================================
//  键帽参数
// ==========================================================
cap_base   = 18.0;
cap_top    = 15.5;
cap_h      = 8.0;
cap_dish   = 0.6;
wall_t     = 1.5;
cross_l    = 4.1;
cross_w    = 1.3;
cross_d    = 4.0;
cap_gap    = (pitch - cap_base) / 2;

module keycap_1u() {
    taper = (cap_base - cap_top) / 2;
    difference() {
        hull() {
            cube([cap_base, cap_base, 0.01]);
            translate([taper, taper, cap_h])
                cube([cap_top, cap_top, 0.01]);
        }
        hull() {
            translate([wall_t, wall_t, -0.01])
                cube([cap_base - 2*wall_t, cap_base - 2*wall_t, 0.01]);
            translate([taper + wall_t, taper + wall_t, cap_h - wall_t])
                cube([cap_top - 2*wall_t, cap_top - 2*wall_t, 0.01]);
        }
        translate([taper + 1, taper + 1, cap_h - cap_dish + 0.01])
            cube([cap_top - 2, cap_top - 2, cap_dish + 0.01]);
        translate([cap_base/2, cap_base/2, -0.01]) {
            translate([-cross_l/2, -cross_w/2, 0])
                cube([cross_l, cross_w, cross_d + 0.01]);
            translate([-cross_w/2, -cross_l/2, 0])
                cube([cross_w, cross_l, cross_d + 0.01]);
        }
    }
    post_s = 1.2;
    translate([cap_base/2, cap_base/2, 0]) {
        for (sx = [-1, 1]) for (sy = [-1, 1])
            translate([sx*(cross_l/2+post_s/2)-post_s/2,
                       sy*(cross_l/2+post_s/2)-post_s/2, 0])
                cube([post_s, post_s, cross_d + 1]);
    }
}

module keycap_2x2() {
    w = 2 * pitch - 2 * cap_gap;
    w_top = w - 3;
    h = cap_h + 2;
    taper = (w - w_top) / 2;
    difference() {
        hull() {
            cube([w, w, 0.01]);
            translate([taper, taper, h]) cube([w_top, w_top, 0.01]);
        }
        hull() {
            translate([wall_t, wall_t, -0.01])
                cube([w - 2*wall_t, w - 2*wall_t, 0.01]);
            translate([taper+wall_t, taper+wall_t, h-wall_t])
                cube([w_top - 2*wall_t, w_top - 2*wall_t, 0.01]);
        }
        translate([taper+2, taper+2, h - cap_dish + 0.01])
            cube([w_top - 4, w_top - 4, cap_dish + 0.01]);
        for (dx=[0,1]) for (dy=[0,1]) {
            sx = pitch/2 - cap_gap + dx*pitch;
            sy = pitch/2 - cap_gap + dy*pitch;
            translate([sx, sy, -0.01]) {
                translate([-cross_l/2, -cross_w/2, 0])
                    cube([cross_l, cross_w, cross_d + 0.01]);
                translate([-cross_w/2, -cross_l/2, 0])
                    cube([cross_w, cross_l, cross_d + 0.01]);
            }
        }
    }
    post_s = 1.2;
    for (dx=[0,1]) for (dy=[0,1]) {
        sx = pitch/2 - cap_gap + dx*pitch;
        sy = pitch/2 - cap_gap + dy*pitch;
        translate([sx, sy, 0])
            for (px=[-1,1]) for (py=[-1,1])
                translate([px*(cross_l/2+post_s/2)-post_s/2,
                           py*(cross_l/2+post_s/2)-post_s/2, 0])
                    cube([post_s, post_s, cross_d + 1]);
    }
}

module keycap_batch_1u(cx, cy) {
    sp = cap_base + 2;
    for (r = [0:cy-1]) for (c = [0:cx-1])
        translate([c*sp, r*sp, 0]) keycap_1u();
}

// ==========================================================
//  渲染控制
// ==========================================================
part = 0;  // 0=预览, 1=左板, 2=右板, 3=1U键帽, 4=2x2键帽

if (part == 0) {
    color([0.6,0.6,0.62]) plate_half("left");
    color([0.6,0.6,0.62])
        translate([split_col*pitch + border + 5, 0, 0]) plate_half("right");
    translate([0, total_d + 2*border + 20, 0]) keycap_batch_1u(7, 8);
    translate([160, total_d + 2*border + 20, 0]) keycap_2x2();
}
if (part == 1) plate_half("left");
if (part == 2) plate_half("right");
if (part == 3) keycap_batch_1u(7, 8);
if (part == 4) keycap_2x2();
