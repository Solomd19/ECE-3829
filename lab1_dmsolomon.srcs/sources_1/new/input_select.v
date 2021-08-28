`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Drew Solomon 
// 
// Create Date: 08/27/2021 01:53:54 PM
// Design Name: Drew Solomon
// Module Name: input_select
// Project Name: ECE 3829 Lab 1
// Target Devices: Basys 3
// Tool Versions: 
// Description: Calculates the current mode and numbers to be displayed on the Basys 3 board
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module input_select(
    input [1:0] mode, //sw[15:14] used to select display mode
    input [13:0] slider, //sw[13:0] used to determine what is displayed
    output reg [3:0] displayAOut, //output to seven segment display A
    output reg [3:0] displayBOut, //output to seven segment display B
    output reg [3:0] displayCOut, //output to seven segment display C
    output reg [3:0] displayDOut //output to seven segment display D
    );
    
    wire [5:0] sum = slider[7:4] + slider[3:0]; //Sum of sw[7:4] and sw[3:0] for Mode 2
    wire [7:0] product = slider[7:4] * slider[3:0]; //Product of sw[7:4] and sw[3:0] for Mode 3
    
    always @ (*)
        case (mode)
            2'b00: begin //Mode 0: Hex Value of Slider Switches
                displayAOut = slider[13:12];
                displayBOut = slider[11:8];
                displayCOut = slider[7:4];
                displayDOut = slider[3:0];
            end
            2'b01: begin //Mode 1: Last 4 Nums of WPI ID
                displayAOut = 2;
                displayBOut = 3;
                displayCOut = 1;
                displayDOut = 5;
            end
            2'b10: begin //Mode 2: Hex Value of sw[7:4], sw[3:0], and Sum of sw[7:4] and sw[3:0]
                displayAOut = slider[7:4];
                displayBOut = slider[3:0];
                displayCOut = sum[4];
                displayDOut = sum[3:0];
            end
            2'b11: begin //Mode 3: Hex Value of sw[7:4], sw[3:0], and Product of sw[7:4] and sw[3:0]
                displayAOut = slider[7:4];
                displayBOut = slider[3:0];
                displayCOut = product[7:4];
                displayDOut = product[3:0];
            end
    endcase
    
endmodule
