`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Drew Solomon 
// 
// Create Date: 08/27/2021 03:02:43 PM
// Design Name: Drew Solomon
// Module Name: seven_seg
// Project Name: ECE 3829 Lab 1
// Target Devices: Basys 3
// Tool Versions: 
// Description: Handles converting and displaying calculations to the seven segment displays of the Basys 3 board
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seven_seg(
    input [3:0] displayA, //Data of number to be shown on display A
    input [3:0] displayB, //Data of number to be shown on display B
    input [3:0] displayC, //Data of number to be shown on display C
    input [3:0] displayD, //Data of number to be shown on display D
    input clk, //10 MHz clock signal
    input reset_n, //Reset button, active low    
    output reg [6:0] sevenSegDisplay, //Seven segment display LED input
    output reg [3:0] sevenSegEnable //Seven segment display enable
    );
    
    reg [3:0] currDisplay = 4'b0000; //Holds data of number to be displayed
    reg [15:0] counter; //FFFF = 65535, 2^16 = 65536
    reg [3:0] displaySelect; //Used in enabling the current display
    
    //Preset LED Arrangements for Seven Segment Digits
    parameter off = 7'b1111111; //No segments lit
    parameter zero = 7'b1000000;
    parameter one = 7'b1111001;
    parameter two = 7'b0100100;
    parameter three = 7'b0110000;
    parameter four = 7'b0011001;
    parameter five = 7'b0010010;
    parameter six = 7'b0000010;
    parameter seven = 7'b1111000;
    parameter eight = 7'b0000000;
    parameter nine = 7'b0011000;
    parameter ten = 7'b0001000; //A
    parameter eleven = 7'b0000011; //B
    parameter twelve = 7'b1000110; //C
    parameter thirteen = 7'b0100001; //D
    parameter fourteen = 7'b0000110; //E
    parameter fifteen = 7'b0001110; //F
    
    parameter delay = 25000; //Delay of 10ms for the 25MHz clock input
    
    always @ (posedge clk) begin
        if (reset_n == 0) begin
            counter <= 0; //When reset is activated, counter resets
            displaySelect <= 4'b0001; //When reset is activated, display starts at D
        end
        else if (counter == delay) begin
            counter <= 0; //After 10ms delay, counter is reset and display shifted
            displaySelect <= {displaySelect[2:0], displaySelect[3]}; //Shift display enable to the left every 10ms, wrap around after A
        end
        else begin
            counter <= counter + 1; //Increment counter every 1/25MHz
        end
    end
    
    always @ (posedge clk) begin//Enables one of the four seven segment displays based on displaySelect, or turns them off if reset active
        if(reset_n == 0)begin
            sevenSegEnable = 4'b1111;
            currDisplay = off;
        end
        else case (displaySelect)
            4'b0001: begin
                sevenSegEnable = 4'b1110;
                currDisplay = displayD;
            end
            4'b0010: begin
                sevenSegEnable = 4'b1101;
                currDisplay = displayC;
            end
            4'b0100: begin
                sevenSegEnable = 4'b1011;
                currDisplay = displayB;
            end
            4'b1000: begin
                sevenSegEnable = 4'b0111;
                currDisplay = displayA;
            end
            
        endcase
        
    end
    
    always @ (posedge clk) begin //Converts number to display into seven segment output
        if(reset_n == 0) begin
            sevenSegDisplay = off;            
        end        
        else begin
            case (currDisplay)
                4'h0: sevenSegDisplay = zero;
                4'h1: sevenSegDisplay = one;
                4'h2: sevenSegDisplay = two;
                4'h3: sevenSegDisplay = three;
                4'h4: sevenSegDisplay = four;
                4'h5: sevenSegDisplay = five;
                4'h6: sevenSegDisplay = six;
                4'h7: sevenSegDisplay = seven;
                4'h8: sevenSegDisplay = eight;
                4'h9: sevenSegDisplay = nine;
                4'hA: sevenSegDisplay = ten;
                4'hB: sevenSegDisplay = eleven;
                4'hC: sevenSegDisplay = twelve;
                4'hD: sevenSegDisplay = thirteen;
                4'hE: sevenSegDisplay = fourteen;
                4'hF: sevenSegDisplay = fifteen;                                              
            endcase
        end
   end
endmodule
