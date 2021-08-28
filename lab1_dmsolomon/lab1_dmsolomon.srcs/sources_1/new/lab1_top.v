`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Drew Solomon
// 
// Create Date: 08/27/2021 02:09:03 PM
// Design Name: Drew Solomon
// Module Name: lab1_top
// Project Name: ECE 3829 Lab 1
// Target Devices: Basys 3
// Tool Versions: 
// Description: Instantiates input_select and seven_seg to calculate numbers to display based on inputs and display on seven segment displays
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab1_top(
    input [15:0] sw, //Switches 0-15
    input btnU, //Up Button
    input btnL, //Left Button
    input btnR, //Right Button
    input btnD, //Down Button
    output [15:0] led, //LED 0-15
    output [6:0] seg, //Seven Segment Display LED 0-6
    output [3:0] an //Seven Segment Display Enable 0-3
    );
    
    wire [3:0] displayA, displayB, displayC, displayD; //Current number to display on each display
    
    wire [3:0] button; //Wire consisting of all button inputs
    assign button[0] = btnU;
    assign button[1] = btnL;
    assign button[2] = btnR;
    assign button[3] = btnD;
    
    //Module instantiations
    input_select input_select_1 (.mode(sw[15:14]), .slider(sw[13:0]), .displayAOut(displayA), .displayBOut(displayB), .displayCOut(displayC), .displayDOut(displayD));
    seven_seg seven_seg_1(.displayA(displayA), .displayB(displayB), .displayC(displayC), .displayD(displayD), .btn(button), .sevenSegDisplay(seg), .sevenSegEnable(an));
    
    assign led[15:0] = sw[15:0]; //LEDs turn on with corresponding switch   
    
endmodule
