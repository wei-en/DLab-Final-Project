`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/02 07:11:30
// Design Name: 
// Module Name: stage_control
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


module stage_control(
    input wire clk,
    input wire reset_n,
    input wire gameover,
    input wire usr_sw0,
    input wire eaten_error1,
    input wire eaten_error2,
    input wire eaten_warning,
    input wire [9:0] pixel_x,
    input wire [9:0] pixel_y,
    output wire landa_region_out,
    output wire [11:0] rgb_next,
    output reg [9:0] score,
    output reg [3:0] stage
    );

localparam goal_score = 100;
localparam img_index_2 = 4745;
localparam LANDA_W = 65;
localparam LANDA_H = 73;
localparam switch_time = 100000000;

// game region
localparam UI_rightmost_x = 627;
localparam landa_y = 394;

reg [26:0] switch_stage_counter; // 1 sec
reg [20:0] walk_speed_ctrl;
reg [13:0] img_index_ctrl;

wire sw_on;
wire sw_off;
reg prev_sw;
always @(posedge clk)begin
    prev_sw <= usr_sw0;
end
assign sw_on = ( prev_sw != usr_sw0 ) && usr_sw0;
assign sw_off = ( prev_sw != usr_sw0 ) && ~usr_sw0;

// skip stage animation
reg [9:0] landa_x;
wire [13:0] addr;
wire [11:0] data_o;
landa_rom landa_rom0
  (.clk(clk),
  .addr(addr),
  .data_o(data_o));

wire landa_region;
assign landa_region = ( pixel_x + LANDA_W >= landa_x && pixel_x < landa_x )
						&& ( pixel_y >= landa_y && pixel_y < landa_y + LANDA_H );
assign addr = (landa_region) ? img_index_ctrl + ( pixel_y - landa_y )*LANDA_W + ( pixel_x + LANDA_W - landa_x) : 14'b0;
assign rgb_next = data_o ;

assign landa_region_out = (data_o!=12'h0f0);

reg start;
always @(posedge clk)begin
    if(~reset_n)begin
        walk_speed_ctrl <= 21'b0;
        landa_x <= UI_rightmost_x + LANDA_W + 1;
        switch_stage_counter <= 27'b0;
        img_index_ctrl <= 14'b0;
        stage <= 4'b0000;
        start <= 4'b0;
        score <= 10'b0;
    end else if (start && stage==4'b0)begin // start game
        stage <= 4'b0001;
        start <= 4'b0;
    end else if (start && stage!=4'b0) begin // skip stage
        walk_speed_ctrl <= (&walk_speed_ctrl) ? 21'b0 : walk_speed_ctrl + 1'b1;
        
        if(&walk_speed_ctrl)
            landa_x <= ( landa_x > UI_rightmost_x ) ? landa_x - 1'b1 : landa_x;
                
        if(landa_x == UI_rightmost_x && &walk_speed_ctrl)
            img_index_ctrl <= (img_index_ctrl != 14'b0) ? 14'b0 : img_index_2;
            
        if(landa_x == UI_rightmost_x)
            switch_stage_counter <= (&switch_stage_counter) ? 27'b0 : switch_stage_counter + 1'b1;
        
        if(&switch_stage_counter)begin
            stage <= (stage<=9) ? stage + 1'b1 : stage;
            start <= 1'b0;
            score <= (score < 999) ? score + 100 : score;
        end
    end else begin
    
        if(landa_x <= UI_rightmost_x + LANDA_W)begin
            walk_speed_ctrl <= (&walk_speed_ctrl) ? 21'b0 : walk_speed_ctrl + 1'b1;
            if(&walk_speed_ctrl)
                landa_x <= landa_x + 1'b1;
        end
        
        if(sw_on)
            start <= 1'b1;
        if (score >= stage*goal_score && stage!=4'b0)
            stage <= (stage<=9) ? stage + 1'b1 : stage;
        
        // add score
        if ( eaten_error2 )
            score <= (score < 999) ? score + 5'b10100 : score;
        else if ( eaten_error1 )
            score <= (score < 999) ? score + 4'b1111 : score;
        else if ( eaten_warning )
            score <= (score < 999) ? score + 4'b1010 : score;        
    end
end  
    
endmodule
