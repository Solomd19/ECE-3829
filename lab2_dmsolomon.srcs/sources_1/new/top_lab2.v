`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: WPI
// Engineer: Drew Solomon
// 
// Create Date: 09/08/2021 11:50:51 PM
// Design Name: Drew Solomon
// Module Name: top_lab2
// Project Name: ECE 3829 Lab 2
// Target Devices: Basys 3
// Tool Versions: 
// Description: Top module for Lab 2
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_lab2(
    input clk,
    input btnC,
    input btnU,
    input [15:14] sw,
    output [6:0] seg,
    output [3:0] an,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output Hsync,
    output Vsync
    );
    
    //WPI ID Last 4 Digits
    parameter [3:0] wpiA = 4'd2;
    parameter [3:0] wpiB = 4'd3;
    parameter [3:0] wpiC = 4'd1;
    parameter [3:0] wpiD = 4'd5;
    
    //Wires to connect data between modules
    wire clk_25mhz; // 25MHz clock
    wire reset; //Active high reset signal for VGA controller
    wire reset_n; //Active low reset signal
    wire sw15Debounced; //Debounced switch 15 signal
    wire sw14Debounced; //Debounced switch 14 signal
    wire btnUDebounced; //Debounced up button signal
    wire blank; //VGA signal to display blank screen
    wire [1:0] sw_debounced = {sw15Debounced, sw14Debounced}; //Register of both debounced switch inputs
    wire [10:0] hcount; //Current pixel horizontal position
    wire [10:0] vcount; //Current pixel vertical position
    
    assign reset = ~reset_n; //Used for the VGA reset which is active high
    
    
    //Module instantiations
    clk_mmcm_wiz clk_mmcm_wiz_i(
        .clk_25MHz(clk_25mhz), //Output
        .reset(btnC), //Input
        .locked(reset_n), //Output
        .clk_in1(clk)); //Input
    
    //Seven Segment Display
    seven_seg seven_seg_i
        (
        .displayA(wpiA),
        .displayB(wpiB),
        .displayC(wpiC),
        .displayD(wpiD),
        .clk(clk_25mhz),
        .reset_n(reset_n),
        .sevenSegDisplay(seg),
        .sevenSegEnable(an));
    
    //Debouncer for sw[15]
    debouncer debouncer_i
        (
        .in(sw[15]),
        .reset_n(reset_n),
        .clk(clk_25mhz),        
        .out(sw15Debounced));
    
    //Debouncer for sw[14]
    debouncer debouncer_ii
        (
        .in(sw[14]),
        .reset_n(reset_n),
        .clk(clk_25mhz),        
        .out(sw14Debounced));

    //Debouncer for btnU
    debouncer debouncer_iv
        (
        .in(btnU),
        .reset_n(reset_n),
        .clk(clk_25mhz),        
        .out(btnUDebounced));
        
    //VGA Controller
    vga_controller_640_60 vga_controller_640_60i
        (
        .pixel_clk(clk_25mhz),
        .rst(reset),
        .HS(Hsync),
        .VS(Vsync),
        .hcount(hcount),
        .vcount(vcount),
        .blank(blank));
        
    //VGA Display
    vga_display vga_display_i
        (
        .sw(sw_debounced),
        .clk(clk_25mhz),
        .reset_n(reset_n),
        .button(btnUDebounced),
        .blank(blank),
        .hcount(hcount),
        .vcount(vcount),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)
        );
    
endmodule
