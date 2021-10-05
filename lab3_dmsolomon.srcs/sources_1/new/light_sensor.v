`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE 3829
// Engineer: Drew Solomon 
// 
// Create Date: 09/18/2021 02:13:14 PM
// Design Name: 
// Module Name: light_sensor
// Project Name: ECE 3829 Lab 3
// Target Devices: Basys 3
// Tool Versions: 
// Description: Handles reading and outputting light sensor data
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module light_sensor
#(parameter SAMPLE_RATE = 10_000_000) //Sample rate = (SAMPLE_RATE/10M ticks) s
    (input clk_10MHz, //10MHz input clock
    input reset_n, //Active low reset signal
    output reg [7:0] sensorOutput, //Reading from light sensor for seven seg display
    output reg JA0, //Chip Select (Active low) (CS)
    input JA2, //Master-in-Slave-out (SPI input) (SDO)
    output reg JA3 //Serial Clock (SCK)
    );
    
    wire rising_edge, falling_edge; //Rising and falling edge triggers
    reg [7:0] intermediateOutput; //Used in transferring sensor data to output
    reg [25:0] counter; //10M ticks = 1s | 2^(25 - 1) = 16.777e6 ticks
    reg [4:0] sclk_counter; //16 SCLK clock cycles = 1 reading
    reg [1:0] state; //FSM state register
    
    //Local Parameters
    localparam RESET = 2'b00;
    localparam WAIT = 2'b01;
    localparam READ = 2'b10;
    localparam rising_edge_count = 0; //Counter clock tick at which rising edge of SCLK is triggered
    localparam falling_edge_count = 5; //Counter clock tick at which falling edge of SCLK is triggered
    
    assign rising_edge = (counter == rising_edge_count) ? 1 : 0; //SCLK rising edge trigger
    assign falling_edge = (counter == falling_edge_count) ? 1 : 0; //SCLK falling edge trigger
    
    always @ (posedge clk_10MHz) begin
        if (state == RESET || (state == READ && counter >= 10)) begin //Create an SCLK signal with an increment frequency of 1MHz           
            counter <= 0; //In READ state, using counter to clock down SCLK to 2MHz, in RESET hold counter at 0 ticks            
        end
        else begin
            counter <= counter + 1; //Else increment counter
        end
    end
    
    
    always @ (posedge clk_10MHz) begin
        if (reset_n == 0) begin //If reset activated, initialize the module            
            state <= RESET;
        end        
        case (state)
                RESET: begin
                    JA0 <= 1; //Deactivate Chip Select
                    state <= WAIT; //Next state after RESET will be WAIT
                end
                WAIT: begin
                    if (counter >= SAMPLE_RATE) begin //After a 1s wait, begin read operation                        
                        sclk_counter <= 0; //Reset Chip Select reset counter
                        sensorOutput <= 0; //Initialize sensor reading                       
                        state <= READ; //After 1s wait (10M clock ticks), begin READ process
                    end
                end
                READ: begin
                    JA0 <= 0; //Activate Chip Select to begin sensor data transfer
                    
                    if (rising_edge) begin //Every half period of SCLK tick, toggle value of SCLK output to create square wave
                        JA3 <= 1; 
                    end
                    else if (falling_edge) begin
                        JA3 <= 0;
                        sclk_counter <= sclk_counter + 1; //Increment SCLK counter by 1 each cycle
                    end
                    
                    if (sclk_counter >= 4 && sclk_counter <= 11 && rising_edge) begin //SCLK ticks 4-11 transmit sensor data
                        if(JA0 == 1) begin
                            intermediateOutput <= 8'h00; //Reset output if Chip Select not activated during read
                        end
                        else begin
                            intermediateOutput <= {intermediateOutput[6:0], JA2}; //Sequentially transmit sensor data MSB first                            
                        end
                    end
                    else if (sclk_counter >= 16) begin //After data is finished transmitting, go to DONE state
                       sclk_counter <= 0; //Reset SCLK counter
                       sensorOutput <= intermediateOutput; //Transfer intermediary reading to output
                       state <= RESET; //Reset FSM to RESET state
                    end
                end             
            endcase
        end    
endmodule
