`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Drew Solomon 
// 
// Create Date: 09/18/2021 02:08:54 PM
// Design Name: 
// Module Name: top_lab3
// Project Name: ECE 3829 Lab 3
// Target Devices: Basys 3
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_lab3(
    input clk, //100 MHz default clock
    input btnC, //Center button
    output JA0, //Chip Select (Active low) (CS)
    input JA2, //Master-in-Slave-out (SPI input) (SDO)
    output JA3, //Serial Clock (SCK)
    output [6:0] seg, //Seven segment LED array
    output [3:0] an //Seven segment enable
    );
    
    //WPI ID Last 4 Digits
    parameter [3:0] wpiA = 4'd2;
    parameter [3:0] wpiB = 4'd3;
    parameter [3:0] wpiC = 4'd1;
    parameter [3:0] wpiD = 4'd5;
    
    //Wires to connect data between modules
    wire clk_10MHz; // 25MHz clock
    wire reset_n; //Active low reset signal
    wire [7:0] sensorOutput;
    
    //Module instantiations
    clock_gen clock_gen_i(
        .clk(clk),
        .btnC(btnC),
        .reset_n(reset_n),
        .clk_10MHz(clk_10MHz)   
    );
    
    light_sensor #(.SAMPLE_RATE(10_000_000))//Sample rate = (SAMPLE_RATE/10M ticks) s
    light_sensor_i (
        .clk_10MHz(clk_10MHz), //10MHz input clock
        .reset_n(reset_n), //Active low reset signal
        .sensorOutput(sensorOutput), //Reading from light sensor for seven seg display
        .JA0(JA0), //Chip Select (Active low) (CS)
        .JA2(JA2), //Master-in-Slave-out (SPI input) (SDO)
        .JA3(JA3) //Serial Clock (SCK)    
    );
    
    seven_seg seven_seg_i(
        .displayA(wpiC), //Data of number to be shown on display A
        .displayB(wpiD), //Data of number to be shown on display B
        .displayC(sensorOutput[7:4]), //Data of number to be shown on display C
        .displayD(sensorOutput[3:0]), //Data of number to be shown on display D
        .clk(clk_10MHz), //10MHz clock signal
        .reset_n(reset_n), //Reset button, active low 
        .sevenSegDisplay(seg), //Seven segment display LED input
        .sevenSegEnable(an) //Seven segment display enable
    );
    
endmodule
