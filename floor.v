`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2019 11:31:19 PM
// Design Name: 
// Module Name: floor
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


module floor(
	input wire clk, // system clock
    input wire reset_n,
    input wire [3:0]  level, 
    input wire [9:0]  pixel_x, // x coordinate of the next pixel (between 0 ~ 639)
    input wire [9:0]  pixel_y, // y coordinate of the next pixel (between 0 ~ 479)
    input wire [9:0]  dope_x,
    input wire [9:0]  dope_y,
    input wire jump,
    output reg grounded,
    output reg floor_region,  // 0 or 1
    output reg [11:0] rgb_next
    );
    reg ground = 0;
    reg [31:0] slow_clk;
    always @(posedge clk) begin
        if(~reset_n)
            slow_clk <= 1'b0;
        else
            slow_clk <= (&slow_clk) ? 32'b0 : slow_clk + 1'b1;
    end
	
	localparam leftmost_x = 13;
	localparam ceiling_y = 88;
	localparam floor_y = 108;
	localparam FLOOR_W = 20;
    localparam LEFT_BOUNDARY = 13;
	localparam RIGHT_BOUNDARY = 627;
	
	reg  [9:0] addr;
	wire [9:0] floor_addr; // input to floor-rom, max 400
    wire [11:0] floor_out; // output from floor-rom
	//number-rom module here
    floor_rom rom(.clk(clk), .addr(floor_addr), .data_o(floor_out));
	assign floor_addr = addr;
    wire floor_A, floor_B, floor_C, floor_D, floor_E, floor_F, floor_G, floor_H, floor_I, floor_J, floor_K, floor_L; 
    //A~J rest, K~L moving floor (not finish yet)
    reg [9:0] moving_index0, moving_index1;
    always @(*)begin
        case(level)
            4'b0001: floor_region = (floor_A || floor_D || floor_E || floor_F || floor_G || floor_H || floor_I || floor_J);
            4'b0010: floor_region = (floor_A || floor_E || floor_G || floor_H || floor_I || floor_J);
            4'b0011: floor_region = (floor_A || floor_D || floor_E || floor_H || floor_J);
            4'b0100: floor_region = (floor_B || floor_F || floor_G || floor_I || floor_J);
            4'b0101: floor_region = (floor_B || floor_D || floor_F || floor_G || floor_I || floor_J);
            4'b0110: floor_region = (floor_B || floor_D || floor_F || floor_G || floor_H || floor_J);
            4'b0111: floor_region = (floor_C || floor_D || floor_E || floor_K || floor_I || floor_J);
            4'b1000: floor_region = (floor_C || floor_D || floor_G || floor_H || floor_L);
            4'b1001: floor_region = (floor_C || floor_F || floor_K || floor_I || floor_L);
            default: floor_region = 0;
        endcase
    end
//    assign floor_region = ((floor_A || floor_D || floor_E || floor_F || floor_G || floor_H || floor_I || floor_J) && level==1) 
//                        || ((floor_A || floor_E || floor_G || floor_H || floor_I || floor_J) && level==2) 
//                        || ((floor_A || floor_D || floor_E || floor_H || floor_J) && level==3) 
//                        || ((floor_B || floor_F || floor_G || floor_I || floor_J) && level==4) 
//                        || ((floor_B || floor_D || floor_F || floor_G || floor_I || floor_J) && level==5) 
//                        || ((floor_B || floor_D || floor_F || floor_G || floor_H || floor_J) && level==6) 
//                        || ((floor_C || floor_D || floor_E || floor_K || floor_I || floor_J) && level==7)
//                        || ((floor_C || floor_D || floor_G || floor_H || floor_L) && level==8) 
//                        || ((floor_C || floor_F || floor_K || floor_I || floor_L) && level==9);
    assign floor_A = (pixel_x >= leftmost_x && pixel_x < leftmost_x + 32*FLOOR_W && pixel_y >= ceiling_y+360 && pixel_y < floor_y+360);
    assign floor_B = ((pixel_x >= leftmost_x && pixel_x < leftmost_x + 10*FLOOR_W) 
                            || (pixel_x >= leftmost_x + 19*FLOOR_W && pixel_x < leftmost_x + 26*FLOOR_W))
                            && (pixel_y >= ceiling_y+360 && pixel_y < floor_y+360);
    assign floor_C = ((pixel_x >= leftmost_x && pixel_x < leftmost_x + 7*FLOOR_W)
                            || (pixel_x >= leftmost_x + 4*FLOOR_W && pixel_x < leftmost_x + 10*FLOOR_W)
                            || (pixel_x >= leftmost_x + 16*FLOOR_W && pixel_x < leftmost_x + 22*FLOOR_W))
                            && (pixel_y >= ceiling_y+360 && pixel_y < floor_y+360);
    assign floor_D = (pixel_x >= 220+leftmost_x && pixel_x < leftmost_x + 26*FLOOR_W && pixel_y >= ceiling_y+60 && pixel_y < floor_y+60);
    assign floor_E = (pixel_x >= 420+leftmost_x && pixel_x < leftmost_x + 30*FLOOR_W && pixel_y >= ceiling_y+120 && pixel_y < floor_y+120);
    assign floor_F = (pixel_x >= leftmost_x && pixel_x < leftmost_x + 12*FLOOR_W && pixel_y >= ceiling_y+120 && pixel_y < floor_y+120);
    assign floor_G = (pixel_x >= 80+leftmost_x && pixel_x < leftmost_x + 16*FLOOR_W && pixel_y >= ceiling_y+180 && pixel_y < floor_y+180);
    assign floor_H = (pixel_x >= 160+leftmost_x && pixel_x < leftmost_x + 17*FLOOR_W && pixel_y >= ceiling_y+240 && pixel_y < floor_y+240);
    assign floor_I = (pixel_x >= 480+leftmost_x && pixel_x < leftmost_x + 31*FLOOR_W && pixel_y >= ceiling_y+240 && pixel_y < floor_y+240);
    assign floor_J = (pixel_x >= 280+leftmost_x && pixel_x < leftmost_x + 24*FLOOR_W && pixel_y >= ceiling_y+300 && pixel_y < floor_y+300);
    assign floor_K = ( pixel_x >= moving_index0 +6 && pixel_x < moving_index0 +6 + 5*FLOOR_W && pixel_y >= ceiling_y+180 && pixel_y < floor_y+180);
    assign floor_L = ( pixel_x >= moving_index1 && pixel_x < moving_index1 + 7*FLOOR_W && pixel_y >= ceiling_y+300 && pixel_y < floor_y+300);
    
    
    wire grounded_A, grounded_B, grounded_C, grounded_D, grounded_E, grounded_F, grounded_G, grounded_H, grounded_I, grounded_J, grounded_K, grounded_L;
    always @(*)begin
            case(level)
                4'b0001: grounded = (~jump) && (grounded_A || grounded_D || grounded_E || grounded_F || grounded_G || grounded_H || grounded_I || grounded_J);
                4'b0010: grounded = (~jump) && (grounded_A || grounded_E || grounded_G || grounded_H || grounded_I || grounded_J);
                4'b0011: grounded = (~jump) && (grounded_A || grounded_D || grounded_E || grounded_H || grounded_J);
                4'b0100: grounded = (~jump) && (grounded_B || grounded_F || grounded_G || grounded_I || grounded_J);
                4'b0101: grounded = (~jump) && (grounded_B || grounded_D || grounded_F || grounded_G || grounded_I || grounded_J);
                4'b0110: grounded = (~jump) && (grounded_B || grounded_D || grounded_F || grounded_G || grounded_H || grounded_J);
                4'b0111: grounded = (~jump) && (grounded_C || grounded_D || grounded_E || grounded_K || grounded_I || grounded_J);
                4'b1000: grounded = (~jump) && (grounded_C || grounded_D || grounded_G || grounded_H || grounded_L);
                4'b1001: grounded = (~jump) && (grounded_C || grounded_F || grounded_K || grounded_I || grounded_L);
                default: grounded = 0;
            endcase
        end
//    assign grounded = (~jump) && (((grounded_A || grounded_D || grounded_E || grounded_F || grounded_G || grounded_H || grounded_I || grounded_J) && level==1) 
//                        || ((grounded_A || grounded_E || grounded_G || grounded_H || grounded_I || grounded_J) && level==2) 
//                        || ((grounded_A || grounded_D || grounded_E || grounded_H || grounded_J) && level==3) 
//                        || ((grounded_B || grounded_F || grounded_G || grounded_I || grounded_J) && level==4) 
//                        || ((grounded_B || grounded_D || grounded_F || grounded_G || grounded_I || grounded_J) && level==5) 
//                        || ((grounded_B || grounded_D || grounded_F || grounded_G || grounded_H || grounded_J) && level==6) 
//                        || ((grounded_C || grounded_D || grounded_E || grounded_K || grounded_I || grounded_J) && level==7)
//                        || ((grounded_C || grounded_D || grounded_G || grounded_H || grounded_L) && level==8) 
//                        || ((grounded_C || grounded_F || grounded_K || grounded_I || grounded_L) && level==9) );
    
    assign grounded_A = (dope_x >= leftmost_x && dope_x -52 < leftmost_x + 32*FLOOR_W && dope_y > ceiling_y+358 && dope_y < ceiling_y+362);
    assign grounded_B = ((dope_x >= leftmost_x && dope_x -52 < leftmost_x + 10*FLOOR_W)
                            || (dope_x >= leftmost_x + 19*FLOOR_W && dope_x -52 < leftmost_x + 26*FLOOR_W))
                            && (dope_y > ceiling_y+358 && dope_y < ceiling_y+362);
    assign grounded_C = ((dope_x >= leftmost_x && dope_x < leftmost_x + 7*FLOOR_W)
                            || (dope_x >= leftmost_x + 4*FLOOR_W && dope_x -52 < leftmost_x + 10*FLOOR_W)
                            || (dope_x >= leftmost_x + 16*FLOOR_W && dope_x -52 < leftmost_x + 22*FLOOR_W))
                            && (dope_y > ceiling_y+358 && dope_y < ceiling_y+362);
    assign grounded_D = (dope_x >= 220+leftmost_x && dope_x -52 < leftmost_x + 26*FLOOR_W && dope_y > ceiling_y+58 && dope_y < ceiling_y+62);
    assign grounded_E = (dope_x >= 420+leftmost_x && dope_x -52 < leftmost_x + 30*FLOOR_W && dope_y > ceiling_y+118 && dope_y < ceiling_y+122);
    assign grounded_F = (dope_x >= leftmost_x && dope_x -52 < leftmost_x + 12*FLOOR_W && dope_y > ceiling_y+118 && dope_y < ceiling_y+122);
    assign grounded_G = (dope_x >= 80+leftmost_x && dope_x -52 < leftmost_x + 16*FLOOR_W && dope_y > ceiling_y+178 && dope_y < ceiling_y+182);
    assign grounded_H = (dope_x >= 160+leftmost_x && dope_x -52 < leftmost_x + 17*FLOOR_W && dope_y > ceiling_y+238 && dope_y < ceiling_y+242);
    assign grounded_I = (dope_x >= 480+leftmost_x && dope_x -52 < leftmost_x + 31*FLOOR_W && dope_y > ceiling_y+238 && dope_y < ceiling_y+242);
    assign grounded_J = (dope_x >= 280+leftmost_x && dope_x -52 < leftmost_x + 24*FLOOR_W && dope_y > ceiling_y+298 && dope_y < ceiling_y+302);
    assign grounded_K = (dope_x >= moving_index0 && dope_x -52 < moving_index0 + 5*FLOOR_W && dope_y > ceiling_y+178 && dope_y < ceiling_y+182);
    assign grounded_L = (dope_x >= moving_index1 && dope_x -52 < moving_index1 + 7*FLOOR_W && dope_y > ceiling_y+298 && dope_y < ceiling_y+302);
    
    //assign grounded = (~jump) && (grounded_A || grounded_D || grounded_E || grounded_F || grounded_G || grounded_H || grounded_I || grounded_J );
    
    always @(posedge clk) begin
		if(~reset_n)begin
		  addr <= 10'b0;
		  moving_index0 <= RIGHT_BOUNDARY;
		  moving_index1 <= leftmost_x + 60;
        end else begin
            if(&slow_clk[23:0]) moving_index0 <= (moving_index0 > LEFT_BOUNDARY ) ? moving_index0 - 5'b1_0100 : RIGHT_BOUNDARY;
            if(&slow_clk[22:0]) moving_index1 <= (moving_index1 < RIGHT_BOUNDARY ) ? moving_index1 + 5'b1_0100 : LEFT_BOUNDARY;
            if(floor_region)
                addr <= (pixel_y - ceiling_y - 20*(( pixel_y - ceiling_y )/20))*FLOOR_W + pixel_x - leftmost_x - 20*(( pixel_x - leftmost_x )/20);  
		end	
	end
	
	always @(*) begin
		if(floor_region)
			rgb_next = (floor_out != 12'h0f0) ? floor_out : 12'hAAA;
    end
    
endmodule