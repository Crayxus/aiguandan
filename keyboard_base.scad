// ============================================================
//  CRAYXUS Guandan Keyboard — Gravity Planet Base
//  重力星球底座 — 带角度键盘托架
//  适配: Bambu A1 (256×256mm), 分左右两半打印
// ============================================================

$fn = 80;

// ===== 键盘尺寸 =====
kb_w       = 290;      // 键盘总宽 (拼合后)
kb_d       = 160;      // 键盘总深
plate_t    = 3.0;      // 定位板厚度

// ===== 底座参数 =====
base_w     = 310;      // 底座宽 (比键盘宽20mm)
base_d     = 185;      // 底座深
tilt_angle = 12;       // 倾斜角度 (度)
base_h_back = 45;      // 后端高度
base_h_front = 6;      // 前端高度 (唇边)
wall       = 3.0;      // 壁厚
lip_h      = 4.0;      // 前唇高度 (防滑)

// ===== 星球曲面 =====
sphere_r   = 600;      // 底面球面半径 (越大越平缓)

// ===== 分割 =====
split_x    = base_w / 2;

// ===== 卡扣 =====
tab_w      = 4.0;
tab_d      = 18.0;
tab_tol    = 0.15;
n_tabs     = 3;

// ===== 派生 =====
side_pad   = (base_w - kb_w) / 2;
front_pad  = (base_d - kb_d) / 2;

// ==========================================================
//  星球底面 — 大球面切割出弧形底
// ==========================================================
module planet_curve(w, d, h) {
    // 用一个大球和长方体的交集做弧形底
    intersection() {
        // 原始楔形
        cube([w, d, h]);
        // 球面 (球心在底面下方)
        translate([w/2, d/2, -sphere_r + h * 0.7])
            sphere(r = sphere_r);
    }
}

// ==========================================================
//  楔形主体 — 前低后高的倾斜托架
// ==========================================================
module wedge_body(w, d) {
    // 后端高, 前端低
    hull() {
        // 前面底边
        translate([0, 0, 0])
            cube([w, 1, base_h_front]);
        // 后面底边
        translate([0, d - 1, 0])
            cube([w, 1, base_h_back]);
    }
}

// ==========================================================
//  键盘凹槽 — 键盘嵌入的凹坑
// ==========================================================
module kb_recess(w, d) {
    // 倾斜的凹槽, 深度=定位板厚度+1mm余量
    recess_d = plate_t + 1.5;
    hull() {
        // 前端
        translate([side_pad, front_pad, base_h_front - recess_d + lip_h])
            cube([kb_w, 1, recess_d]);
        // 后端
        translate([side_pad, front_pad + kb_d - 1, base_h_back - recess_d])
            cube([kb_w, 1, recess_d + 1]);
    }
}

// ==========================================================
//  理线槽 — 后方USB线出口
// ==========================================================
module cable_channel() {
    // 后部中央开槽
    translate([base_w/2 - 10, base_d - wall - 1, 8])
        cube([20, wall + 2, 12]);
}

// ==========================================================
//  防滑纹理 — 底部同心圆环
// ==========================================================
module grip_rings() {
    for (i = [1 : 5]) {
        r = i * 20;
        difference() {
            translate([base_w/2, base_d/2, 0])
                cylinder(r = r, h = 0.6);
            translate([base_w/2, base_d/2, -0.1])
                cylinder(r = r - 1.2, h = 0.8);
        }
    }
}

// ==========================================================
//  完整底座 (单半)
// ==========================================================
module base_half(side = "left") {
    is_left = (side == "left");
    clip_x = is_left ? 0 : split_x;
    clip_w = is_left ? split_x : base_w - split_x;

    difference() {
        union() {
            // 主体: 楔形 + 星球弧面底
            intersection() {
                wedge_body(base_w, base_d);
                // 星球弧面 — 底面微弧
                translate([base_w/2, base_d/2, -sphere_r + base_h_back * 0.5])
                    sphere(r = sphere_r);
            }

            // 前唇 (防止键盘前滑)
            translate([side_pad, front_pad - 2, base_h_front])
                cube([kb_w, 4, lip_h]);

            // 后挡 (轻微凸起)
            translate([side_pad, front_pad + kb_d, base_h_back - plate_t - 1])
                cube([kb_w, 3, plate_t + 2]);

            // 卡扣 (左半凸出)
            if (is_left) {
                tab_spacing = (base_d - n_tabs * tab_d) / (n_tabs + 1);
                for (i = [0 : n_tabs - 1]) {
                    ty = tab_spacing * (i + 1) + tab_d * i;
                    // 计算此处高度 (楔形插值)
                    frac = (ty + tab_d/2) / base_d;
                    local_h = base_h_front + (base_h_back - base_h_front) * frac;
                    translate([split_x, ty, 0])
                        cube([tab_w, tab_d, local_h * 0.8]);
                }
            }
        }

        // 键盘凹槽
        kb_recess(base_w, base_d);

        // 内腔掏空 (省料, 留壁厚)
        translate([wall, wall, wall])
            wedge_body(base_w - 2*wall, base_d - 2*wall);

        // 理线槽
        cable_channel();

        // 卡槽 (右半凹进)
        if (!is_left) {
            tab_spacing = (base_d - n_tabs * tab_d) / (n_tabs + 1);
            slot_w = tab_w + tab_tol * 2;
            slot_d = tab_d + tab_tol * 2;
            for (i = [0 : n_tabs - 1]) {
                ty = tab_spacing * (i + 1) + tab_d * i - tab_tol;
                frac = (ty + tab_d/2) / base_d;
                local_h = base_h_front + (base_h_back - base_h_front) * frac;
                translate([split_x - slot_w, ty, -0.01])
                    cube([slot_w + 0.01, slot_d, local_h * 0.8 + 0.02]);
            }
        }

        // 切半
        if (is_left) {
            translate([split_x + tab_w + 0.01, -1, -1])
                cube([base_w, base_d + 2, base_h_back + 20]);
        } else {
            translate([-base_w + split_x - 0.01, -1, -1])
                cube([base_w, base_d + 2, base_h_back + 20]);
        }
    }

    // 底部防滑圆环 (只在各自半边范围)
    intersection() {
        grip_rings();
        translate([clip_x, 0, 0])
            cube([clip_w, base_d, 1]);
    }
}

// ==========================================================
//  装饰: 星球环 (土星环风格, 底座侧面)
// ==========================================================
module planet_ring() {
    translate([base_w/2, base_d/2, base_h_back * 0.3])
    rotate([90, 0, 0])
    difference() {
        cylinder(r = base_d/2 + 5, h = 2, center = true);
        cylinder(r = base_d/2 - 3, h = 3, center = true);
    }
}

// ==========================================================
//  渲染控制
// ==========================================================
part = 0;  // 0=预览, 1=左半, 2=右半

if (part == 0) {
    // 预览: 两半拼合 + 透明键盘轮廓
    color([0.15, 0.15, 0.18]) base_half("left");
    color([0.15, 0.15, 0.18]) base_half("right");

    // 键盘轮廓 (透明参考)
    %translate([side_pad, front_pad, base_h_front + lip_h])
        rotate([atan2(base_h_back - base_h_front - lip_h, kb_d), 0, 0])
            cube([kb_w, kb_d, 5]);
}
if (part == 1) base_half("left");
if (part == 2) base_half("right");
