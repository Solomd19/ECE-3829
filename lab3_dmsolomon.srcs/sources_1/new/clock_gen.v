`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Drew Solomon 
// 
// Create Date: 09/18/2021 03:34:23 PM
// Design Name: Drew Solomon
// Module Name: clock_gen
// Project Name: ECE 3829 Lab 3
// Target Devices: Basys 3
// Tool Versions: 
// Description: Generates 10MHz clock output and active low reset signal
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clock_gen(
    input clk, //100MHz clock input
    input btnC, //Center button
    output reg reset_n, //Active low reset signal
    output clk_10MHz //10MHz clock output
    );
    
    wire locked_i;
    reg locked_ii;
    
    //Run output through two consecutive flip flops to remove metastability
    always @ (posedge clk_10MHz) begin
        locked_ii <= locked_i;
        reset_n <= locked_ii;
    end
    
    //Clock module instantiation for 10MHz clock and reset signal
    clk_wiz_0 clk_wiz_0_i(
        .clk_10MHz(clk_10MHz), //Output
        .reset(btnC), //Input
        .locked(locked_i), //Output
        .clk_in1(clk)); //Input
    
endmodule
