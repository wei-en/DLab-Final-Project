`timescale 1ns / 1ps

module life_control(
    input wire clk,
    input wire reset_n,
    input wire usr_sw3,
    input wire [3:0] stage,
    input wire [9:0] chara_y,
    input wire chara_region,
    input wire [2:0] enemy_region,
    output reg [2:0] life,
    output reg gameover
    );

localparam V_H = 480;

wire changed;
reg [3:0] prev_stage;
always @(posedge clk)begin
    prev_stage <= stage;
end
assign changed = ( prev_stage != stage );

wire changed_sw;
reg prev_sw;
always @(posedge clk)begin
    prev_sw <= usr_sw3;
end
assign changed_sw = ( prev_sw != usr_sw3 ) && usr_sw3;


reg [26:0] cooldown_time;
always @(posedge clk)begin
    if( ~reset_n || changed || changed_sw)begin
        //reset
        life <= 3'b101;
        cooldown_time <= 27'b0;
        gameover <= 1'b0;
    end else begin
        if(life == 3'b0 || chara_y >= V_H )
            gameover <= 1'b1;
        cooldown_time <= (cooldown_time==27'b0) ? cooldown_time : cooldown_time - 1'b1;
        if( chara_region && |(enemy_region) && cooldown_time==27'b0)begin
            life <= ( life != 0 ) ? life-1'b1 : life;
            cooldown_time <= 27'b111_1111_1111_1111_1111_1111_1111;
        end
    end
end

endmodule
