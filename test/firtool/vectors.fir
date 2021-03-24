; RUN: firtool %s  -enable-lower-types -lower-to-rtl -verilog | FileCheck %s 
circuit vec1:
  module vec1:
    input b1: UInt<1>
    input b2: UInt<1>
    input b3: UInt<1>
    output a: UInt<1>[4]

    a[0] <= b1
    a[1] <= b2
    a[2] <= b3
    a[3] <= b1
; CHECK: module vec1(
; CHECK:   input  b1, b2, b3,
; CHECK:   output a_0, a_1, a_2, a_3);
; CHECK:   assign a_0 = b1;
; CHECK:   assign a_1 = b2;
; CHECK:   assign a_2 = b3;
; CHECK:   assign a_3 = b1;
; CHECK: endmodule

  module vec2:
    input a: {wo: UInt<1>, valid: UInt<2>}[4]
    output b: {wo: UInt<1>, valid: UInt<2>}

    b.wo <= a[0].wo
    b.valid <= a[1].valid
; CHECK: module vec2(
; CHECK:   input        a_0_wo,
; CHECK:   input  [1:0] a_0_valid,
; CHECK:   input        a_1_wo,
; CHECK:   input  [1:0] a_1_valid,
; CHECK:   input        a_2_wo,
; CHECK:   input  [1:0] a_2_valid,
; CHECK:   input        a_3_wo,
; CHECK:   input  [1:0] a_3_valid,
; CHECK:   output       b_wo,
; CHECK:   output [1:0] b_valid);
; CHECK:   assign b_wo = a_0_wo;	
; CHECK:   assign b_valid = a_1_valid;	
; CHECK: endmodule

  module vec3:
    input a: {wo: UInt<1>[4], valid: UInt<2>[4]}
    output b: {wo: UInt<1>, valid: UInt<2>}

    b.wo <= a.wo[0]
    b.valid <= a.valid[1]
; CHECK: module vec3(
; CHECK:   input        a_wo_0, a_wo_1, a_wo_2, a_wo_3,
; CHECK:   input  [1:0] a_valid_0, a_valid_1, a_valid_2, a_valid_3,
; CHECK:   output       b_wo,
; CHECK:   output [1:0] b_valid);
; 
; CHECK:   assign b_wo = a_wo_0;	
; CHECK:   assign b_valid = a_valid_1;	
; CHECK: endmodule

  module vec4:
    input a: UInt<2>[4]
    output b: UInt<2>

    wire z : UInt<2>[4]
    z[0] <= UInt<2>("h1")
    z[1] <= UInt<2>("h0")
    z[2] <= UInt<2>("h1")
    z[3] <= UInt<2>("h2")
    b <= a[z[2]]
; CHECK: module vec4(
; CHECK:   input  [1:0] a_0, a_1, a_2, a_3,
; CHECK:   output [1:0] b);
; 
; CHECK:   wire [1:0] z_2;	
; 
; CHECK:   assign z_2 = 2'h1;	
; CHECK:   wire [1:0] _T = z_2;	
; CHECK:   assign b = &_T ? a_3 : _T == 2'h2 ? a_2 : _T == 2'h1 ? a_1 : a_0;	
; CHECK: endmodule

  module vec5:
    input a: UInt<2>[4][4]
    output b: UInt<2>

    b <= a[0][2]
; CHECK: module vec5(
; CHECK:   input  [1:0] a_0_0, a_0_1, a_0_2, a_0_3, a_1_0, a_1_1, a_1_2, a_1_3, a_2_0, a_2_1, a_2_2, a_2_3, a_3_0, a_3_1, a_3_2,
; CHECK:   input  [1:0] a_3_3,
; CHECK:   output [1:0] b);
; 
; CHECK:   assign b = a_0_2;	
; CHECK: endmodule

  module vec6:
    input a: UInt<1>[4]
    input sel: UInt<2>
    output b: UInt<2>

    wire z : UInt<1>[4]
    z[0] <= UInt<1>("h1")
    z[1] <= UInt<1>("h0")
    z[2] <= UInt<1>("h1")
    z[3] <= UInt<1>("h0")
    b <= sub(a[sel],z[sel])
; CHECK: module vec6(
; CHECK:   input        a_0, a_1, a_2, a_3,
; CHECK:   input  [1:0] sel,
; CHECK:   output [1:0] b);
; 
; CHECK:   wire z_0;	
; CHECK:   wire z_1;	
; CHECK:   wire z_2;	
; CHECK:   wire z_3;	
; 
; CHECK:   assign z_0 = 1'h1;	
; CHECK:   assign z_1 = 1'h0;	
; CHECK:   assign z_2 = 1'h1;	
; CHECK:   assign z_3 = 1'h0;	
; CHECK:   wire _T = sel == 2'h1;	
; CHECK:   wire _T_0 = sel == 2'h2;	
; CHECK:   wire _T_1 = &sel;	
; CHECK:   wire [1:0] _tmp = {1'h0, _T_1 ? a_3 : _T_0 ? a_2 : _T ? a_1 : a_0};	
; CHECK:   wire [1:0] _tmp_2 = {1'h0, _T_1 ? z_3 : _T_0 ? z_2 : _T ? z_1 : z_0};	
; CHECK:   assign b = _tmp - _tmp_2;	
; CHECK: endmodule

  module vec7:
    input a: {wo: UInt<1>, valid: UInt<2>}[4]
    input sel: UInt<2>
    output b: {wo: UInt<1>, valid: UInt<2>}

    b.wo <= a[sel].wo
    b.valid <= a[sel].valid
; CHECK: module vec7(
; CHECK:   input        a_0_wo,
; CHECK:   input  [1:0] a_0_valid,
; CHECK:   input        a_1_wo,
; CHECK:   input  [1:0] a_1_valid,
; CHECK:   input        a_2_wo,
; CHECK:   input  [1:0] a_2_valid,
; CHECK:   input        a_3_wo,
; CHECK:   input  [1:0] a_3_valid, sel,
; CHECK:   output       b_wo,
; CHECK:   output [1:0] b_valid);
; 
; CHECK:   wire _T = sel == 2'h1;	
; CHECK:   wire _T_0 = sel == 2'h2;	
; CHECK:   wire _T_1 = &sel;	
; CHECK:   assign b_wo = _T_1 ? a_3_wo : _T_0 ? a_2_wo : _T ? a_1_wo : a_0_wo;	
; CHECK:   assign b_valid = _T_1 ? a_3_valid : _T_0 ? a_2_valid : _T ? a_1_valid : a_0_valid;	
; CHECK: endmodule

  module vec8:
    input a: {wo: UInt<1>[4], valid: UInt<2>[4]}
    input sel: UInt<2>
    output b: {wo: UInt<1>, valid: UInt<2>}

    b.wo <= a.wo[sel]
    b.valid <= a.valid[sel]
; CHECK: module vec8(
; CHECK:   input        a_wo_0, a_wo_1, a_wo_2, a_wo_3,
; CHECK:   input  [1:0] a_valid_0, a_valid_1, a_valid_2, a_valid_3, sel,
; CHECK:   output       b_wo,
; CHECK:   output [1:0] b_valid);
; 
; CHECK:   wire _T = sel == 2'h1;	
; CHECK:   wire _T_0 = sel == 2'h2;	
; CHECK:   wire _T_1 = &sel;	
; CHECK:   assign b_wo = _T_1 ? a_wo_3 : _T_0 ? a_wo_2 : _T ? a_wo_1 : a_wo_0;	
; CHECK:   assign b_valid = _T_1 ? a_valid_3 : _T_0 ? a_valid_2 : _T ? a_valid_1 : a_valid_0;	
; CHECK: endmodule

  module vec9:
    input a: UInt<2>[4]
    input sel: UInt<2>
    output b: UInt<2>

    wire z : UInt<2>[4]
    z[0] <= UInt<2>("h1")
    z[1] <= UInt<2>("h0")
    z[2] <= UInt<2>("h1")
    z[3] <= UInt<2>("h2")
    b <= a[z[sel]]
; CHECK: module vec9(
; CHECK:   input  [1:0] a_0, a_1, a_2, a_3, sel,
; CHECK:   output [1:0] b);
; 
; CHECK:   wire [1:0] z_0;	
; CHECK:   wire [1:0] z_1;	
; CHECK:   wire [1:0] z_2;	
; CHECK:   wire [1:0] z_3;	
; 
; CHECK:   assign z_0 = 2'h1;	
; CHECK:   assign z_1 = 2'h0;	
; CHECK:   assign z_2 = 2'h1;	
; CHECK:   assign z_3 = 2'h2;	
; CHECK:   wire [1:0] _T = &sel ? z_3 : sel == 2'h2 ? z_2 : sel == 2'h1 ? z_1 : z_0;	
; CHECK:   assign b = &_T ? a_3 : _T == 2'h2 ? a_2 : _T == 2'h1 ? a_1 : a_0;	
; CHECK: endmodule

  module vec10:
    input a: UInt<2>[4][4]
    input sel1: UInt<2>
    input sel2: UInt<2>
    output b: UInt<2>

    b <= a[sel1][sel2]
; CHECK: module vec10(
; CHECK:   input  [1:0] a_0_0, a_0_1, a_0_2, a_0_3, a_1_0, a_1_1, a_1_2, a_1_3, a_2_0, a_2_1, a_2_2, a_2_3, a_3_0, a_3_1, a_3_2,
; CHECK:   input  [1:0] a_3_3, sel1, sel2,
; CHECK:   output [1:0] b);
; 
; CHECK:   wire _T = sel2 == 2'h1;	
; CHECK:   wire _T_0 = sel1 == 2'h0;	
; CHECK:   wire _T_1 = sel2 == 2'h2;	
; CHECK:   wire _T_2 = &sel2;	
; CHECK:   wire _T_3 = sel2 == 2'h0;	
; CHECK:   wire _T_4 = sel1 == 2'h1;	
; CHECK:   wire _T_5 = sel1 == 2'h2;	
; CHECK:   wire _T_6 = &sel1;	
; CHECK:   wire [1:0] _tmp = _T_1 & _T_0 ? a_0_2 : _T & _T_0 ? a_0_1 : a_0_0;	
; CHECK:   wire [1:0] _tmp_7 = _T_3 & _T_4 ? a_1_0 : _T_2 & _T_0 ? a_0_3 : _tmp;	
; CHECK:   wire [1:0] _tmp_8 = _T_1 & _T_4 ? a_1_2 : _T & _T_4 ? a_1_1 : _tmp_7;	
; CHECK:   wire [1:0] _tmp_9 = _T_3 & _T_5 ? a_2_0 : _T_2 & _T_4 ? a_1_3 : _tmp_8;	
; CHECK:   wire [1:0] _tmp_10 = _T_1 & _T_5 ? a_2_2 : _T & _T_5 ? a_2_1 : _tmp_9;	
; CHECK:   wire [1:0] _tmp_11 = _T_3 & _T_6 ? a_3_0 : _T_2 & _T_5 ? a_2_3 : _tmp_10;	
; CHECK:   wire [1:0] _tmp_12 = _T_1 & _T_6 ? a_3_2 : _T & _T_6 ? a_3_1 : _tmp_11;	
; CHECK:   assign b = _T_2 & _T_6 ? a_3_3 : _tmp_12;	
; CHECK: endmodule

  module vec11:
    input a: {wo: UInt<1>, valid: UInt<2>}[2][2]
    input sel: UInt<1>
    output b: {wo: UInt<1>, valid: UInt<2>}

    b.wo <= a[sel][sel].wo
    b.valid <= a[sel][sel].valid
; CHECK: module vec11(
; CHECK:   input        a_0_0_wo,
; CHECK:   input  [1:0] a_0_0_valid,
; CHECK:   input        a_0_1_wo,
; CHECK:   input  [1:0] a_0_1_valid,
; CHECK:   input        a_1_0_wo,
; CHECK:   input  [1:0] a_1_0_valid,
; CHECK:   input        a_1_1_wo,
; CHECK:   input  [1:0] a_1_1_valid,
; CHECK:   input        sel,
; CHECK:   output       b_wo,
; CHECK:   output [1:0] b_valid);
; 
; CHECK:   wire _T = ~sel;	
; CHECK:   wire _T_0 = sel & _T;	
; CHECK:   wire _T_1 = _T & sel;	
; CHECK:   wire [1:0] _tmp = _T_1 ? a_1_0_valid : _T_0 ? a_0_1_valid : a_0_0_valid;	
; CHECK:   assign b_wo = sel ? a_1_1_wo : _T_1 ? a_1_0_wo : _T_0 ? a_0_1_wo : a_0_0_wo;	
; CHECK:   assign b_valid = sel ? a_1_1_valid : _tmp;	
; CHECK: endmodule
