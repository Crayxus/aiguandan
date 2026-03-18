// ============================================================
//  CRAYXUS 掼蛋一体机 — Mecha-Cat Cyberpunk Console v3
//  机甲猫 × 隐形战机 × 赛博朋克
//
//  设计理念: 每一面都有科技元素, 没有平平无奇的表面
//  打印: Bambu A1 (256×256mm), 分块打印后拼合
// ============================================================

$fn = 60;

// ===== 键盘尺寸 =====
kb_pitch   = 19.05;
kb_cols    = 15;
kb_rows    = 8;
kb_w       = kb_cols * kb_pitch;   // 285.75mm
kb_d       = kb_rows * kb_pitch;   // 152.4mm

// ===== 13.3寸 OLED =====
scr_module_w = 304;
scr_module_h = 179;
scr_module_t = 4.0;
scr_bezel    = 5;
scr_active_w = scr_module_w - 2*scr_bezel;
scr_active_h = scr_module_h - 2*scr_bezel;

// ===== 树莓派5 =====
rpi_w = 85;
rpi_d = 56;
rpi_h = 20;

// ===== 底座参数 =====
base_w       = 360;       // 总宽 (含侧翼)
base_d       = 240;       // 总深
base_h_front = 32;        // 前端高度
base_h_back  = 50;        // 后端高度
wall         = 3.0;
corner_r     = 4;

// 侧翼
wing_ext     = 15;        // 翼展突出量
wing_h       = 8;         // 翼厚

// 键盘嵌入
kb_x         = (base_w - kb_w) / 2;
kb_y         = 35;
kb_recess    = 5.0;

// RPi位置
rpi_x        = base_w/2 - rpi_w/2;
rpi_y        = kb_y + kb_d + 12;

// ===== 翻盖参数 =====
lid_w        = base_w;
lid_d        = 220;
lid_h_edge   = 8;         // 边缘厚
lid_h_spine  = 14;        // 脊椎隆起最高点

// ===== 铰链 =====
hinge_r      = 8;
hinge_pin_r  = 3.0;
hinge_w      = 28;
hinge_seg    = 5;

// ===== 猫脸 =====
eye_r        = 14;
eye_spacing  = 110;
eye_z        = base_h_front * 0.55;

// ===== LED灯槽 =====
led_w        = 4;
led_depth    = 2.5;

// ===== 预览角度 =====
lid_angle    = 115;

// ===== 分割 =====
split_x      = base_w / 2;
tab_w        = 5;
tab_d        = 22;
tab_tol      = 0.15;


// ==========================================================
//  六角蜂巢镂空图案 (2D)
// ==========================================================
module hex_grid(w, h, hex_r, gap) {
    dx = (hex_r + gap) * 1.732;
    dy = (hex_r + gap) * 1.5;
    cols = ceil(w / dx) + 1;
    rows = ceil(h / dy) + 1;
    intersection() {
        square([w, h]);
        for (r = [0:rows]) {
            ox = (r % 2) * dx / 2;
            for (c = [0:cols]) {
                translate([ox + c * dx, r * dy])
                    circle(r=hex_r, $fn=6);
            }
        }
    }
}


// ==========================================================
//  底座外形 — 隐形战机轮廓
//  前窄后宽, 多切面, 侧翼延伸
// ==========================================================
module stealth_base_body() {
    // 主体: 前窄后宽的棱角体
    hull() {
        // 前排 — 收窄, 像战斗机鼻锥
        translate([40, 0, 0])
            cube([base_w - 80, 1, base_h_front]);
        // 中前排
        translate([15, base_d * 0.3, 0])
            cube([base_w - 30, 1, base_h_front + 3]);
        // 中后排 — 最宽
        translate([0, base_d * 0.7, 0])
            cube([base_w, 1, base_h_back - 5]);
        // 后排
        translate([8, base_d, 0])
            cube([base_w - 16, 1, base_h_back]);
    }
}

// 侧翼 — 战斗机散热翼
module side_wings() {
    // 左翼
    hull() {
        translate([0, base_d * 0.35, base_h_front * 0.3])
            cube([1, 60, wing_h]);
        translate([-wing_ext, base_d * 0.45, base_h_front * 0.4])
            cube([1, 30, wing_h * 0.5]);
    }
    // 右翼
    hull() {
        translate([base_w - 1, base_d * 0.35, base_h_front * 0.3])
            cube([1, 60, wing_h]);
        translate([base_w + wing_ext - 1, base_d * 0.45, base_h_front * 0.4])
            cube([1, 30, wing_h * 0.5]);
    }
}

// 前脸装甲斜切
module front_armor_cuts() {
    // 上部大斜切 — 隐形战机风挡角度
    translate([-1, -15, base_h_front - 2])
        rotate([-25, 0, 0])
            cube([base_w + 2, 40, 25]);

    // 左侧前脸斜切
    translate([-1, -1, base_h_front * 0.6])
        rotate([0, 0, 0])
        hull() {
            translate([0, 0, 0]) cube([25, 1, base_h_front * 0.5]);
            translate([15, base_d * 0.15, 0]) cube([1, 1, base_h_front * 0.3]);
        }

    // 右侧前脸斜切
    translate([base_w - 24, -1, base_h_front * 0.6])
        hull() {
            translate([0, 0, 0]) cube([25, 1, base_h_front * 0.5]);
            translate([9, base_d * 0.15, 0]) cube([1, 1, base_h_front * 0.3]);
        }
}

// 侧面多层装甲切面
module side_armor_cuts() {
    // 左侧上斜切
    translate([-1, 20, base_h_front * 0.75])
        rotate([0, 15, 0])
            cube([15, base_d - 40, 20]);
    // 右侧上斜切
    translate([base_w - 14, 20, base_h_front * 0.75])
        rotate([0, -15, 0])
            cube([15, base_d - 40, 20]);

    // 左侧中间凹槽 (装甲板缝隙)
    translate([-0.1, 30, base_h_front * 0.45])
        cube([1.5, base_d * 0.6, 2]);
    // 右侧
    translate([base_w - 1.4, 30, base_h_front * 0.45])
        cube([1.5, base_d * 0.6, 2]);
}


// ==========================================================
//  机甲猫眼 — 凶猛angular设计
// ==========================================================
module mecha_cat_eye() {
    rotate([90, 0, 0]) {
        // 主眼眶 — 菱形而非椭圆
        linear_extrude(wall + 4)
            polygon([
                [0, eye_r * 0.7],
                [eye_r * 1.1, 0],
                [0, -eye_r * 0.5],
                [-eye_r * 1.1, 0]
            ]);
    }
}

// 猫眼LED环槽
module eye_led_ring() {
    rotate([90, 0, 0])
        difference() {
            scale([1, 0.7, 1])
                cylinder(r=eye_r + 3, h=2);
            translate([0, 0, -0.1])
                scale([1, 0.7, 1])
                    cylinder(r=eye_r + 1, h=2.2);
        }
}

// V形鼻脊 — 更锋利
module mecha_nose() {
    translate([base_w/2, 0, eye_z - 20]) {
        // 中央刀刃
        hull() {
            translate([0, -5, 0]) sphere(r=3.5);
            translate([-35, 0, 18]) sphere(r=1.5);
        }
        hull() {
            translate([0, -5, 0]) sphere(r=3.5);
            translate([35, 0, 18]) sphere(r=1.5);
        }
        // 额外装甲线
        hull() {
            translate([0, -3, -5]) sphere(r=2);
            translate([-20, 0, 3]) sphere(r=1);
        }
        hull() {
            translate([0, -3, -5]) sphere(r=2);
            translate([20, 0, 3]) sphere(r=1);
        }
    }
}

// 嘴部六角格栅
module mecha_mouth_grille() {
    translate([base_w/2 - 30, -0.5, base_h_front * 0.08])
        rotate([90, 0, 0])
            linear_extrude(wall + 2)
                hex_grid(60, 10, 2.5, 1.2);
}


// ==========================================================
//  六角装饰塔 (四角, 带LED凹坑)
// ==========================================================
module corner_turret(h) {
    tr = 14;
    difference() {
        union() {
            cylinder(r=tr, h=10, $fn=6);
            // 底座环
            cylinder(r=tr + 2, h=2, $fn=6);
        }
        // LED凹坑
        translate([0, 0, 4])
            cylinder(r=tr - 3, h=8, $fn=6);
        // 顶部倒角
        translate([0, 0, 8])
            cylinder(r1=0, r2=tr + 3, h=5, $fn=6);
    }
}

// 小型六角螺栓装饰
module hex_bolt(h=3) {
    cylinder(r=3.5, h=h, $fn=6);
    translate([0, 0, h])
        cylinder(r=2, h=1, $fn=6);
}


// ==========================================================
//  底座后方 — 散热格栅区
// ==========================================================
module rear_hex_vents() {
    // 后壁六角镂空
    translate([base_w * 0.2, base_d - wall - 0.5, base_h_back * 0.3])
        rotate([90, 0, 0])
            linear_extrude(wall + 2)
                hex_grid(base_w * 0.6, base_h_back * 0.35, 3.5, 1.5);
}


// ==========================================================
//  铰链筒 (底座侧)
// ==========================================================
module base_hinges() {
    total = hinge_seg * hinge_w;
    start_x = (base_w - total) / 2;
    for (i = [0 : 2 : hinge_seg-1]) {
        translate([start_x + i * hinge_w, 0, 0])
            rotate([0, 90, 0])
                difference() {
                    cylinder(r=hinge_r, h=hinge_w - 0.5);
                    translate([0, 0, -1])
                        cylinder(r=hinge_pin_r + 0.3, h=hinge_w + 2);
                }
    }
}


// ==========================================================
//  完整底座
// ==========================================================
module base_shell() {
    difference() {
        union() {
            stealth_base_body();
            side_wings();
            mecha_nose();

            // 铰链筒 (后方顶部)
            translate([0, base_d + hinge_r - 2, base_h_back])
                base_hinges();

            // 四角六角塔
            translate([25, 25, base_h_front - 2])
                corner_turret(base_h_front);
            translate([base_w - 25, 25, base_h_front - 2])
                corner_turret(base_h_front);
            translate([25, base_d - 25, base_h_back - 2])
                corner_turret(base_h_back);
            translate([base_w - 25, base_d - 25, base_h_back - 2])
                corner_turret(base_h_back);

            // 边缘六角螺栓装饰
            for (y = [60, 120, 180]) {
                translate([8, y, base_h_front * 0.5]) hex_bolt();
                translate([base_w - 8, y, base_h_front * 0.5]) hex_bolt();
            }

            // 前唇 — 锋利的V形
            hull() {
                translate([base_w/2 - 50, 0, base_h_front - 8])
                    cube([100, 2, 1]);
                translate([base_w/2 - 30, -3, base_h_front - 5])
                    cube([60, 1, 1]);
            }
        }

        // 内腔掏空
        translate([wall + 15, wall, wall]) {
            hull() {
                translate([0, 0, 0])
                    cube([base_w - 2*wall - 30, base_d * 0.3, base_h_front]);
                translate([-15, base_d * 0.7, 0])
                    cube([base_w - 2*wall, base_d * 0.25, base_h_back]);
            }
        }

        // 键盘凹槽
        translate([kb_x, kb_y, base_h_front - kb_recess])
            cube([kb_w, kb_d, kb_recess + 20]);

        // RPi仓位
        translate([rpi_x, rpi_y, wall]) {
            cube([rpi_w + 4, rpi_d + 4, rpi_h + 5]);
            translate([-3, -3, rpi_h])
                cube([rpi_w + 10, rpi_d + 10, 10]);
        }

        // === 前脸装甲切面 ===
        front_armor_cuts();
        side_armor_cuts();

        // === 机甲猫眼 (穿透前壁) ===
        translate([base_w/2 - eye_spacing/2, 2, eye_z])
            mecha_cat_eye();
        translate([base_w/2 + eye_spacing/2, 2, eye_z])
            mecha_cat_eye();

        // === 猫眼LED环槽 ===
        translate([base_w/2 - eye_spacing/2, 1, eye_z])
            eye_led_ring();
        translate([base_w/2 + eye_spacing/2, 1, eye_z])
            eye_led_ring();

        // === 嘴部格栅 ===
        mecha_mouth_grille();

        // === 前面LED灯槽 (双线) ===
        translate([50, -0.01, base_h_front * 0.18])
            cube([base_w - 100, led_depth, led_w]);
        translate([50, -0.01, base_h_front * 0.25])
            cube([base_w - 100, led_depth, led_w * 0.6]);

        // === 左右侧LED灯槽 ===
        translate([-0.01, 50, base_h_front * 0.5])
            cube([led_depth, base_d - 100, led_w]);
        translate([base_w - led_depth + 0.01, 50, base_h_front * 0.5])
            cube([led_depth, base_d - 100, led_w]);

        // === 后方六角散热 ===
        rear_hex_vents();

        // === 后方接口 ===
        translate([base_w/2 - 8, base_d - wall - 1, wall + 5])
            cube([16, wall + 2, 10]);  // USB-C
        translate([base_w/2 + 30, base_d - wall - 1, wall + 5])
            cube([16, wall + 2, 7]);   // HDMI
        translate([base_w/2 - 45, base_d - wall - 1, wall + 5])
            cube([12, wall + 2, 7]);   // 键盘USB

        // === 底部六角通风 ===
        translate([base_w/2 - 60, 50, -0.1])
            linear_extrude(wall + 0.2)
                hex_grid(120, 100, 4, 2);

        // === 侧面装甲板线 (浅槽) ===
        // 前侧斜线
        for (side = [0, 1]) {
            mx = side * (base_w - 1.5);
            translate([mx, 15, base_h_front * 0.3])
                cube([1.5, 40, 1.2]);
            translate([mx, 70, base_h_front * 0.6])
                cube([1.5, 50, 1.2]);
        }
    }
}


// ==========================================================
//  翻盖 — 脊椎隆起 + 几何背面
// ==========================================================
module lid_body() {
    // 主体: 边薄中厚, 脊椎隆起
    hull() {
        // 铰链边 (Y=0)
        translate([15, 0, 0]) cube([lid_w - 30, 1, lid_h_edge]);
        // 中部 — 脊椎最高
        translate([8, lid_d * 0.4, 0]) cube([lid_w - 16, 1, lid_h_spine]);
        // 前缘 (Y=lid_d)
        translate([20, lid_d, 0]) cube([lid_w - 40, 1, lid_h_edge]);
    }
}

// 背面力量线 (脊椎 + 分支)
module spine_ridges() {
    // 中央脊椎
    hull() {
        translate([lid_w/2 - 3, 15, lid_h_spine])
            cube([6, 1, 2]);
        translate([lid_w/2 - 2, lid_d * 0.4, lid_h_spine])
            cube([4, 1, 3]);
        translate([lid_w/2 - 3, lid_d - 20, lid_h_edge])
            cube([6, 1, 2]);
    }

    // 左分支脊线
    hull() {
        translate([lid_w/2 - 3, lid_d * 0.3, lid_h_spine])
            cube([3, 1, 2]);
        translate([40, lid_d * 0.5, lid_h_edge])
            cube([3, 1, 2]);
    }
    // 右分支脊线
    hull() {
        translate([lid_w/2, lid_d * 0.3, lid_h_spine])
            cube([3, 1, 2]);
        translate([lid_w - 43, lid_d * 0.5, lid_h_edge])
            cube([3, 1, 2]);
    }
}

// 背面六角装甲板
module back_hex_panels() {
    // 左面板
    translate([25, 30, lid_h_edge + 0.5])
        linear_extrude(1.5)
            hex_grid(lid_w/2 - 50, lid_d * 0.5, 5, 2);
    // 右面板
    translate([lid_w/2 + 25, 30, lid_h_edge + 0.5])
        linear_extrude(1.5)
            hex_grid(lid_w/2 - 50, lid_d * 0.5, 5, 2);
}

// 背面CRAYXUS品牌区
module brand_area() {
    translate([lid_w/2, lid_d * 0.7, lid_h_edge + 1]) {
        // 菱形边框
        linear_extrude(1)
            difference() {
                rotate([0, 0, 45]) square([18, 18], center=true);
                rotate([0, 0, 45]) square([14, 14], center=true);
            }
    }
}

module lid_shell() {
    difference() {
        union() {
            lid_body();
            spine_ridges();
            brand_area();

            // 前缘小翼 (关闭时露出的锋利边)
            hull() {
                translate([30, lid_d - 2, 0])
                    cube([lid_w - 60, 2, lid_h_edge]);
                translate([50, lid_d + 3, 0])
                    cube([lid_w - 100, 1, lid_h_edge * 0.6]);
            }

            // 边缘六角螺栓
            for (y = [40, lid_d/2, lid_d - 40]) {
                translate([12, y, lid_h_edge]) hex_bolt(2);
                translate([lid_w - 12, y, lid_h_edge]) hex_bolt(2);
            }
        }

        // === 屏幕凹槽 (内侧Z=0) ===
        scr_x = (lid_w - scr_module_w) / 2;
        scr_y = (lid_d - scr_module_h) / 2 + 5;

        // 模组嵌入槽
        translate([scr_x, scr_y, -0.01])
            cube([scr_module_w, scr_module_h, scr_module_t + 0.5]);

        // 活动区域开窗 (穿透)
        translate([scr_x + scr_bezel, scr_y + scr_bezel, -0.01])
            cube([scr_active_w, scr_active_h, lid_h_spine + 5]);

        // 内侧HDMI走线槽
        translate([lid_w/2 - 8, -0.01, 0.5])
            cube([16, scr_y + 5, 4]);

        // 内侧边框装甲线
        translate([scr_x - 3, scr_y - 3, -0.01])
            difference() {
                cube([scr_module_w + 6, scr_module_h + 6, 1.5]);
                translate([2, 2, -0.1])
                    cube([scr_module_w + 2, scr_module_h + 2, 1.7]);
            }

        // === 背面切面 ===
        // 前缘斜切
        translate([-1, lid_d - 5, lid_h_edge])
            rotate([-12, 0, 0])
                cube([lid_w + 2, 15, 10]);

        // 侧面斜切
        translate([-1, -1, lid_h_edge])
            rotate([0, 10, 0])
                cube([15, lid_d + 2, 15]);
        translate([lid_w - 14, -1, lid_h_edge])
            rotate([0, -10, 0])
                cube([15, lid_d + 2, 15]);

        // === LED灯槽 ===
        // 前缘LED (关闭时可见)
        translate([50, lid_d - led_depth + 0.01, lid_h_edge/2 - led_w/2])
            cube([lid_w - 100, led_depth + 0.02, led_w]);

        // 侧面LED
        translate([-0.01, 30, lid_h_edge/2 - 1.5])
            cube([led_depth, lid_d - 60, 3]);
        translate([lid_w - led_depth + 0.01, 30, lid_h_edge/2 - 1.5])
            cube([led_depth, lid_d - 60, 3]);

        // === 背面装甲板线 ===
        for (y = [lid_d*0.25, lid_d*0.55]) {
            translate([20, y, lid_h_edge - 0.5])
                cube([lid_w - 40, 1.2, 2]);
        }
    }
}


// ==========================================================
//  铰链 (翻盖侧)
// ==========================================================
module lid_hinges() {
    total = hinge_seg * hinge_w;
    start_x = (base_w - total) / 2;
    for (i = [1 : 2 : hinge_seg-1]) {
        translate([start_x + i * hinge_w, 0, 0])
            rotate([0, 90, 0])
                difference() {
                    cylinder(r=hinge_r - 1, h=hinge_w - 0.5);
                    translate([0, 0, -1])
                        cylinder(r=hinge_pin_r + 0.3, h=hinge_w + 2);
                }
    }
}


// ==========================================================
//  铰链销
// ==========================================================
module hinge_pin() {
    pin_len = hinge_seg * hinge_w + 6;
    cylinder(r=hinge_pin_r, h=pin_len);
    cylinder(r=hinge_pin_r + 2.5, h=2);
    translate([0, 0, pin_len - 2])
        cylinder(r=hinge_pin_r + 2.5, h=2);
}


// ==========================================================
//  猫脸面板 (独立打印, 贴装前壁)
// ==========================================================
module cat_face_panel() {
    pw = base_w - 80;
    ph = base_h_front - 10;
    pt = 2.5;

    difference() {
        // 面板 — 多切面造型
        hull() {
            translate([5, 0, 5]) rotate([-90, 0, 0]) cylinder(r=5, h=pt);
            translate([pw-5, 0, 5]) rotate([-90, 0, 0]) cylinder(r=5, h=pt);
            translate([0, 0, ph]) cube([pw, pt, 1]);
            translate([15, 0, 0]) cube([pw-30, pt, 1]);
        }

        // 机甲猫眼
        translate([pw/2 - eye_spacing/2, -0.5, ph * 0.6])
            mecha_cat_eye();
        translate([pw/2 + eye_spacing/2, -0.5, ph * 0.6])
            mecha_cat_eye();

        // LED环
        translate([pw/2 - eye_spacing/2, -0.3, ph * 0.6])
            eye_led_ring();
        translate([pw/2 + eye_spacing/2, -0.3, ph * 0.6])
            eye_led_ring();

        // V形鼻线 (刻入)
        translate([pw/2, -0.5, ph * 0.35]) {
            hull() {
                translate([-30, 0, 12]) rotate([-90,0,0]) cylinder(r=0.8, h=pt+1);
                translate([0, 0, 0]) rotate([-90,0,0]) cylinder(r=1.2, h=pt+1);
            }
            hull() {
                translate([30, 0, 12]) rotate([-90,0,0]) cylinder(r=0.8, h=pt+1);
                translate([0, 0, 0]) rotate([-90,0,0]) cylinder(r=1.2, h=pt+1);
            }
        }

        // 六角嘴格栅
        translate([pw/2 - 30, -0.5, ph * 0.05])
            rotate([90, 0, 0])
                linear_extrude(pt + 1)
                    hex_grid(60, 10, 2.5, 1.2);

        // LED横槽
        translate([25, -0.01, ph * 0.15])
            cube([pw - 50, pt + 0.02, led_w]);
    }
}


// ==========================================================
//  底座分割
// ==========================================================
module base_half(side="left") {
    difference() {
        base_shell();
        if (side == "left") {
            translate([split_x + 0.01, -30, -15])
                cube([base_w + wing_ext + 10, base_d + 50, base_h_back + 60]);
        } else {
            translate([-base_w - wing_ext - 10 + split_x - 0.01, -30, -15])
                cube([base_w + wing_ext + 10, base_d + 50, base_h_back + 60]);
        }
    }
    // 卡扣
    if (side == "left") {
        spacing = (base_d - 3 * tab_d) / 4;
        for (i = [0:2]) {
            ty = spacing * (i + 1) + tab_d * i;
            frac = (ty + tab_d/2) / base_d;
            lh = base_h_front + (base_h_back - base_h_front) * frac;
            translate([split_x, ty, wall])
                cube([tab_w, tab_d, lh * 0.5]);
        }
    }
}

module base_right() {
    difference() {
        base_half("right");
        spacing = (base_d - 3 * tab_d) / 4;
        for (i = [0:2]) {
            ty = spacing * (i + 1) + tab_d * i - tab_tol;
            frac = (ty + tab_d/2) / base_d;
            lh = base_h_front + (base_h_back - base_h_front) * frac;
            translate([split_x - tab_w - tab_tol, ty, wall - 0.1])
                cube([tab_w + 2*tab_tol, tab_d + 2*tab_tol, lh*0.5 + 0.2]);
        }
    }
}


// ==========================================================
//  翻盖分割
// ==========================================================
module lid_half(side="left") {
    difference() {
        lid_shell();
        if (side == "left") {
            translate([split_x + 0.01, -10, -5])
                cube([lid_w + 10, lid_d + 20, lid_h_spine + 20]);
        } else {
            translate([-lid_w - 10 + split_x - 0.01, -10, -5])
                cube([lid_w + 10, lid_d + 20, lid_h_spine + 20]);
        }
    }
}


// ==========================================================
//  渲染控制
// ==========================================================
//  0 = 完整预览
//  1 = 底座左半    2 = 底座右半
//  3 = 翻盖左半    4 = 翻盖右半
//  5 = 猫脸面板    6 = 铰链销
part = 0;

if (part == 0) {
    // 底座
    color([0.08, 0.08, 0.10])
        base_shell();

    // 猫脸面板
    color([0.05, 0.05, 0.07])
        translate([40, -2.5, 5])
            cat_face_panel();

    // 翻盖 (打开状态)
    hinge_pivot_y = base_d + hinge_r - 2;
    hinge_pivot_z = base_h_back;

    color([0.10, 0.10, 0.13])
    translate([0, hinge_pivot_y, hinge_pivot_z])
        rotate([lid_angle, 0, 0])
            translate([0, 0, 0]) {
                lid_shell();
                translate([0, 0, lid_h_edge/2])
                    lid_hinges();
            }

    // 键盘参考 (半透明蓝)
    %translate([kb_x, kb_y, base_h_front - kb_recess])
        color([0.3, 0.4, 0.9, 0.4])
            cube([kb_w, kb_d, 3]);

    // RPi参考 (半透明绿)
    %translate([rpi_x + 2, rpi_y + 2, wall])
        color([0.2, 0.8, 0.3, 0.4])
            cube([rpi_w, rpi_d, rpi_h]);

    // 猫眼LED (琥珀光)
    color([1, 0.65, 0, 0.9]) {
        translate([base_w/2 - eye_spacing/2, -3, eye_z])
            sphere(r=4);
        translate([base_w/2 + eye_spacing/2, -3, eye_z])
            sphere(r=4);
    }

    // LED灯条 (青色)
    color([0, 0.9, 0.9, 0.6]) {
        translate([50, -1, base_h_front*0.18 + 1])
            cube([base_w - 100, 0.5, 3]);
        // 侧面
        translate([-1, 50, base_h_front*0.5])
            cube([0.5, base_d - 100, 3]);
        translate([base_w + 0.5, 50, base_h_front*0.5])
            cube([0.5, base_d - 100, 3]);
    }
}

if (part == 1) base_half("left");
if (part == 2) base_right();
if (part == 3) lid_half("left");
if (part == 4) lid_half("right");
if (part == 5) cat_face_panel();
if (part == 6) hinge_pin();
