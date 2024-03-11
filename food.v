`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2019 11:31:19 PM
// Design Name: 
// Module Name: food
// Project Name: 
// Target Devices: 
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


module food #(parameter name = "warning.mem", idx = 1) (
	input wire clk, // system clock
    input wire reset_n,
    input wire eaten_n, //been eaten or not
    input wire [3:0]  level,
    input wire [9:0]  pixel_x, // x coordinate of the next pixel (between 0 ~ 639)
    input wire [9:0]  pixel_y, // y coordinate of the next pixel (between 0 ~ 479)
    output wire food_region,  // 0 or 1
    output reg [11:0] rgb_next
    );
    
    localparam leftmost_x = 13;
	localparam ceiling_y = 83;
	localparam floor_y = 103;
	localparam FOOD_W = 20;
    
    reg [19:0] coordinate[5:0];
	reg [3:0]  index, clk_cnt = 0;
	initial begin
	   index <= idx;
	   coordinate[0] <= {10'd130 + leftmost_x, 10'd340}; //food on A, B, C
	   coordinate[1] <= {10'd570 + leftmost_x, 10'd280}; // on J
	   coordinate[2] <= {10'd540 + leftmost_x, 10'd220}; // on I
	   coordinate[3] <= {10'd260 + leftmost_x, 10'd220}; // on H
	   coordinate[4] <= {10'd90 + leftmost_x, 10'd160}; // on G
	   coordinate[5] <= {10'd420 + leftmost_x, 10'd100}; // on F
	   coordinate[6] <= {10'd260 + leftmost_x, 10'd100}; // on E
	   coordinate[7] <= {10'd470 + leftmost_x, 10'd40}; // on D
	   
	   coordinate[8] <= {10'd420 + leftmost_x, 10'd340}; // on A, B, C
	   coordinate[9] <= {10'd390 + leftmost_x, 10'd280}; // on J
	   coordinate[10] <= {10'd600 + leftmost_x, 10'd220}; // on I
	   coordinate[11] <= {10'd290 + leftmost_x, 10'd220}; // on H
	   coordinate[12] <= {10'd170 + leftmost_x, 10'd160}; // on G
	   coordinate[13] <= {10'd140 + leftmost_x, 10'd100}; // on F
	   coordinate[14] <= {10'd550 + leftmost_x, 10'd100}; // on E
	   coordinate[15] <= {10'd400 + leftmost_x, 10'd40}; // on D
	   
	   coordinate[16] <= {10'd20 + leftmost_x, 10'd340}; //food on A, B, C //available @ every level
	   coordinate[17] <= {10'd480 + leftmost_x, 10'd280}; // on J //available @ Lv 1234567
	   coordinate[18] <= {10'd580 + leftmost_x, 10'd220}; // on I //available @ Lv 12 45 7
	   coordinate[19] <= {10'd230 + leftmost_x, 10'd220}; // on H //available @ Lv 123  6 8
	   coordinate[20] <= {10'd310 + leftmost_x, 10'd160}; // on G //available @ Lv 12 456 8
	   coordinate[21] <= {10'd330 + leftmost_x, 10'd100}; // on F //available @ Lv 1  456  9
	   coordinate[22] <= {10'd470 + leftmost_x, 10'd100}; // on E //available @ Lv 123   7
	   coordinate[23] <= {10'd270 + leftmost_x, 10'd40};  // on D //available @ Lv 1 3 5678 
	   
	   coordinate[24] <= {10'd220 + leftmost_x, 10'd340}; // on A, B, C
	   coordinate[25] <= {10'd190 + leftmost_x, 10'd280}; // on J
	   coordinate[26] <= {10'd200 + leftmost_x, 10'd220}; // on I
	   coordinate[27] <= {10'd370 + leftmost_x, 10'd220}; // on H
	   coordinate[28] <= {10'd250 + leftmost_x, 10'd160}; // on G
	   coordinate[29] <= {10'd40 + leftmost_x, 10'd100}; // on F
	   coordinate[30] <= {10'd90 + leftmost_x, 10'd100}; // on E
	   coordinate[31] <= {10'd160 + leftmost_x, 10'd40}; // on D
	   
	end
	
	always@(posedge clk)begin
	   if(eaten_n)begin
           index <= index + idx;
	   end
	end
	
	reg  [9:0] addr;
	wire [9:0] food_addr; // input to food-rom, max 800
    wire [11:0] food_out; // output from food-rom
	//number-rom module here
    food_rom #(.name(name)) 
    fd_rom1(
        .clk(clk), 
        .addr(food_addr), 
        .data_o(food_out)   );
	assign food_addr = addr;
    
    
    assign food_region = (pixel_x >= coordinate[index][19:10] && pixel_x < coordinate[index][19:10] + FOOD_W ) && (pixel_y >= ceiling_y + coordinate[index][9:0] && pixel_y < floor_y + coordinate[index][9:0]);
    
    always @(posedge clk) begin
		if(~reset_n)begin
		  addr <= 10'b0;
        end else begin
            if(food_region)
                addr <= (pixel_y - ceiling_y - coordinate[index][9:0] )*FOOD_W + pixel_x - coordinate[index][19:10];  
            else addr <= 10'b0;
		end	
	end
	
	always @(*) begin
		if(food_region)
			rgb_next = (food_out != 12'h0f0) ? food_out : 12'hAAA;
    end
    
endmodule