`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Drew Solomon  
// 
// Create Date: 09/26/2021 01:50:45 AM
// Design Name: 
// Module Name: lab3_tb
// Project Name: ECE 3829 Lab 3
// Target Devices: Basys 3 
// Tool Versions: 
// Description: Test bench for ECE 3829 Lab 3
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab3_tb(
    );
    
    //Registers and wires
    reg clk_10MHz;
    reg reset_n;
    reg [14:0] SDO_DATA;
    reg [7:0] expectedReading;
    wire [7:0] actualReading;
    reg [7:0] lastActual;
    reg SDO;   
    wire CS_N;
    wire SCLK;
    integer i, j;
    
    //Parameters
    parameter CLK_HALF_PERIOD = 50;
    
    always begin //Generates 10MHz clock
        #CLK_HALF_PERIOD clk_10MHz = ~clk_10MHz;
    end
    
    initial begin
        reset_n = 0;
        clk_10MHz = 0;
        SDO_DATA = 16'b0000_00011000_000;
        #200
        reset_n = 1;
        #200
        for (i = 0; i < 5; i = i + 1) begin
            #1500
            if (i > 0) begin
                if (expectedReading == actualReading) begin
                    $display("PASS: Expected Value: %h, Actual Value: %h", expectedReading, actualReading);
                end
                else begin
                    $display("FAIL: Expected Value %h, Actual Value: %h", expectedReading, actualReading);
                end 
            end
            expectedReading = SDO_DATA[10:3];
            for (j = 0; j < 15; j = j + 1) begin
                 while (CS_N != 0) begin
                    #1;
                end
                 SDO = SDO_DATA[14-j];                  
                 #1000;
            end
            #1000;
            SDO_DATA = SDO_DATA + 16'b0000_00011000_000;
        end
        #600000000
        $stop;    
    end
    
    //ONE SAMPLE EVERY 100 US
    light_sensor #(.SAMPLE_RATE(1_000))//Sample rate = (SAMPLE_RATE/10M ticks) s
    uuti (
        .clk_10MHz(clk_10MHz), //10MHz input clock
        .reset_n(reset_n), //Active low reset signal
        .sensorOutput(actualReading), //Reading from light sensor for seven seg display
        .JA0(CS_N), //Chip Select (Active low) (CS)
        .JA2(SDO), //Master-in-Slave-out (SPI input) (SDO)
        .JA3(SCLK) //Serial Clock (SCK)    
    );
    
endmodule
