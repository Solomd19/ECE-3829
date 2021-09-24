`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Drew Solomon
// 
// Create Date: 09/08/2021 10:44:49 PM
// Design Name: Drew Solomon
// Module Name: vga_display
// Project Name: ECE 3829 Lab 2
// Target Devices: Basys 3
// Tool Versions: 
// Description: Displays differnet VGA outputs depending on sw[15:14]
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vga_display(
    input [1:0] sw, //Switch 15 (MSB) and 14 (LSB) input as a 2 bit register
    input clk, //25 MHz clock signal
    input reset_n, //Reset button, resets count, active low
    input button, //Button input for moving block mode
    input blank, //Signal to display blank screen
    input [10:0] hcount, //Current pixel horizontal position
    input [10:0] vcount, //Current pixel vertical position
    output [3:0] vgaRed, //Color red input for VGA
    output [3:0] vgaGreen, //Color green input for VGA
    output [3:0] vgaBlue //Color blue input for VGA
    );
    
    
    
    //Color parameters
    parameter [11:0] RED = 12'b1111_0000_0000;
    parameter [11:0] GREEN = 12'b0000_1111_0000;
    parameter [11:0] BLUE = 12'b0000_0000_1111;
    parameter [11:0] WHITE = 12'b1111_1111_1111;
    parameter [11:0] BLACK = 12'b0000_0000_0000;
    parameter [11:0] PURPLE = 12'b1111_0000_1111;
    
    //Other parameters and useful registers
    parameter screenHorizontal = 640; //Horizontal size of screen
    parameter screenVertical = 480; //Vertical size of screen
    parameter halfScreenVertical = 240; //Half the vertical size of screen
    parameter MAX_COUNT = 12500000; //Terminal count to reach 2Hz clock using 25MHz input clock
    
    reg [11:0] vgaRGB; //Register used to convey RGB data to VGA color inputs
    reg [10:0] blockPos = 0; //Current position of moving block 2^10 = 1024
    reg [24:0] counter = 0; //Counter used in creating a 2MHz clock for updating the moving block position 2^24 = 16.777e6
    
    //VGA color port assignments
    assign vgaRed = vgaRGB[11:8]; //Assign highest 4 bits of vgaRGB to VGA color red input
    assign vgaGreen = vgaRGB[7:4]; //Assign middle 4 bits of vgaRGB to VGA color green input
    assign vgaBlue = vgaRGB[3:0]; //Assign lowest 4 bits of vgaRGB to VGA color blue input
    
    always @ (posedge clk) begin
        if (reset_n == 0 || button == 0) begin //If reset pressed or button NOT pressed...
            blockPos <= 0; //Reset counter position to left side of screen
            counter <= 0; //Reset counter            
        end
        else begin
            if (counter >= MAX_COUNT) begin //If counter reaches max count...
                counter = 0; //Reset counter
                if (blockPos >= 640) begin //If block has reached right side of screen...
                    blockPos <= 0; //Reset block position to left side of screen
                end
                else begin //If button is being held and hasnt reached right side of screen...
                    blockPos <= blockPos + 16; //Move the position of the block right by 16 pixels
                end
            end
            else begin //If max count hasnt been reached...
                counter <= counter + 1; //Increment counter by 1
            end
        end
    end
    
    always @ (*) begin
        if (blank == 1) begin //If blank signal is high...
            vgaRGB = BLACK; //Display black/blank screen
        end
        else if (button == 1) begin //If block move button is pressed...
            vgaRGB <= BLACK; //Cover screen with black first to overwrite previous image
            if (vcount >= halfScreenVertical - 8 && vcount <= halfScreenVertical + 8) begin //Begin drawing 16x16 block at current position
                if (hcount >= blockPos && hcount <= (blockPos + 16)) begin
                    vgaRGB <= WHITE;
                end                
            end
            else begin
                vgaRGB <= BLACK; //Cover all area not covered by block with black
            end
        end
        else if (sw == 2'b00) begin //If switch 15 is off and switch 14 is off...
             vgaRGB = BLUE; //Display blue screen
        end
        else if (sw == 2'b01) begin //If switch 15 is off and switch 14 is on...
            if (vcount[5] == 1) begin //Display alternating horizontal green and purple stripes, 32 bits in height
                vgaRGB = GREEN;
            end
            else begin
                 vgaRGB = PURPLE;
            end
         end
         else if (sw == 2'b10) begin //If switch 15 is on and switch 14 is off...
             if (vcount >= (screenVertical - 64)) begin //Display a 64x64 pixel red block in the bottom right corner
                 if (hcount >= (screenHorizontal - 64)) begin
                        vgaRGB = RED;
                 end
                 else begin
                     vgaRGB = BLACK; //Cover rest of screen in black
                 end
             end
         end
         else if (sw == 2'b11) begin //If switch 15 is on and switch 14 is on...
            if (hcount <= 16) begin //Display a single, 16 pixel white stripe on left side of screen
                 vgaRGB = WHITE;
            end
            else begin
                vgaRGB = BLACK; //Cover rest in black
            end
         end                        
    end     
endmodule
