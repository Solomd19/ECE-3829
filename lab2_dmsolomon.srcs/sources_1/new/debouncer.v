`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Drew Solomon
// 
// Create Date: 09/07/2021 12:33:02 AM
// Design Name: Drew Solomon
// Module Name: debouncer
// Project Name: ECE 3829 Lab 2
// Target Devices: Basys 3
// Tool Versions: 
// Description: Debounces a button input
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module debouncer(
    input in, //input button press
    input reset_n, //Reset button, resets count, active low
    input clk, //25 MHz clock signal
    output out //debounced button press output
    );
    
    
    parameter terminal_count = 250000; //25MHz * 10msec = 250,000 ticks for 10ms
    
    wire toggle; // = 1 If input is changed    
    
    reg [17:0] count; //Holds current clock tick count 2^18 = 262,144
    reg lastIn; //in reading from last pos clock edge
    reg btnOut; //Register for the debounced output
    
    assign toggle = (lastIn != in) ? 1 : 0; //If the input on the last clock tick does not match the current, it has been toggled
    assign out = btnOut; //Drive out to always = btnOut
    
    always @ (posedge clk) begin
        if (reset_n == 0 || count >= terminal_count) begin
            btnOut <= in; //If reset it being pressed or the terminal count has been reached, btnOut = in
            count <= 0; //Reset count if reset pressed or terminal count reached           
        end
        else if(toggle == 1) begin
            count <= 0; //Reset count if input is toggled          
        end        
        else begin
            count <= count + 1; //Increment counter by 1 if button input is constant
        end
    end
    
    always @ (posedge clk) begin
        lastIn <= in; //Update lastIn every clock tick
    end
    
endmodule