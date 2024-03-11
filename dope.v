            
//    module for main  character dope
module dope(
input clk,
input reset,
input L,input R,input U,
input [3:0]stage,
input grounded,    // input signal when dope is on the platform
input [9:0] pixel_x,
input [9:0] pixel_y,
input video_on,
//input collision,    // input when collision with ghost
//input game_over,
output [9:0] dope_x, 
output[9:0] dope_y,    // coor. of dope
//output direction,    // left = 0 ; right = 1
output d_jump,
output reg [11:0] rgb_next,
output reg dope_on  //0 or 1
);

// Declare system variables
localparam V_W = 640;    //    width
localparam V_H = 480;    //    high
// Platform variables
localparam UP_B = 80;   //boundary
localparam LE_B = 13;
localparam RI_B = 627;
localparam LO_B = 467;

// Dope variables
localparam D_W = 26;
localparam D_H = 44;
reg [9:0] x, y;    
wire [12:0] rom_addr;
wire [11:0] data_out;
reg  [12:0] dope_addr;
reg [12:0] chara_addr[0:3];
wire        dope_region;

//  change stage
reg [3:0] prev_stage;
wire change_stage;
assign change_stage = (prev_stage != stage);
always @(posedge clk)begin
if(~reset) prev_stage <= 0;
else prev_stage <=stage;
end
//  JUMP FSM
reg [2:0] Q, Q_next;
localparam walk = 0;
localparam jump = 1;
localparam down = 2;
//localparam Y_TIME  = 1300000;// 
reg [20:0] Y_TIME [0:2];    //2^21 = 2097152
localparam JUMP_MAX = 120; //  maximum jump height
reg [20:0] y_time; //  time counter for jumping
reg [6:0] jump_count;
reg [8:0] down_count;
reg [20:0] down_time;
reg [1:0] speed;
//   for x move
localparam X_TIME  =   1000000;
reg [20:0] l_time,r_time; // time counter for moving left and right
assign  rom_addr = dope_addr;
// Initializes the dope images starting addresses.
initial begin
    chara_addr[0] <= 0;
    chara_addr[1] <= D_W*D_H;
    chara_addr[2] <= 2*D_W*D_H;
    chara_addr[3] <= 3*D_W*D_H;
    Y_TIME[0] <= 1200000;   //slowest
    Y_TIME[1] <= 800000;
    Y_TIME[2] <= 300000;    //fastest
end
assign  dope_region = pixel_y >= y && pixel_y < (y + D_H*2) &&
   pixel_x > (x - D_W*2) && pixel_x <= x;



reg [23:0] dope_walk_clock;
reg image_switch;
dope_rom #(.DATA_WIDTH(12), .ADDR_WIDTH(13), .ROM_SIZE(4*D_W*D_H))
rom(.clk(clk), .addr(rom_addr), .data_o(data_out));
//  for dope image
always @ (posedge clk) begin
    if (~reset || change_stage) begin
        dope_addr <= 0;
        dope_walk_clock <= 0;
        image_switch <= 0;
    end
    else begin
        dope_walk_clock <= ( &dope_walk_clock ) ? 24'b0 : dope_walk_clock + 1'b1;
        if ( &dope_walk_clock)
            image_switch <= ~image_switch;
        if (dope_region)begin
            if (Q == walk)
                dope_addr <= (L||R) ? chara_addr[image_switch] + // index 0 or 1
                                      ((pixel_y - y) >> 1)*D_W + ((pixel_x +(D_W*2-1)-x) >> 1):
                                      ((pixel_y - y) >> 1)*D_W + ((pixel_x +(D_W*2-1)-x) >> 1);
            else
                dope_addr <= chara_addr[image_switch + 2'b10] + // index 2 or 3
                             ((pixel_y - y) >> 1)*D_W + ((pixel_x +(D_W*2-1)-x) >> 1);
        end
    end
end
/*Output logic*/
assign  dope_x = x;
assign  dope_y = y;
assign  d_jump = (Q == jump)? 1 : 0;
// Direction Signal
/*
reg dir;
assign  direction = dir;

always @(posedge clk) begin
    if (~reset || change_stage) dir <= 1;
end

always @(posedge clk) begin
    if(L && !R) dir <= 0;
    if(R && !L) dir <= 1;
end
*/
// x move
// no dir/left/right 
always @(posedge clk) begin
    if (~reset || change_stage) begin
        x <= 20*6 + LE_B;
        l_time <= 0;
        r_time <= 0;
    end
    else begin
    if(!L && !R)begin //no dir
        l_time <= 0;
        r_time <= 0;
    end

    if(L && !R && x >= D_W*2 + LE_B) begin //left
        r_time <= 0;
        if (l_time < X_TIME) l_time <= l_time + 1;
        else if (l_time == X_TIME)begin
            x <= x - 1;
            l_time <= 0;
        end
    end
    if (!L && R && x <= RI_B)begin //right
        l_time <= 0;
        if (r_time < X_TIME) r_time <= r_time + 1;
        else if (r_time == X_TIME)begin
            x <= x + 1;
            r_time <= 0;
        end
    end
    end
end

// y move
// walk /jump /down
// FSM for y moving
always @(posedge clk) begin
    if (~reset || change_stage) begin
        Q <= walk;
    end
    else begin
      Q <= Q_next;
    end
end
always @(*) begin
    case(Q)
    walk:
        begin
            if (!grounded) Q_next = down;
            else if (U) Q_next = jump;
            else Q_next = walk;
        end
    jump:
        begin
            if (U && jump_count < JUMP_MAX && y > 10'b0) Q_next = jump;
            else Q_next = down;
        end
    down:
        begin
            if (grounded) Q_next = walk;
            else Q_next = down;
        end
    endcase 
end

always @(posedge clk) begin
    if (~reset || change_stage) begin
        y <= LO_B - 20 - D_H*2 + 1;
        y_time <= 0;
        jump_count <= 0;
        down_count <= 0;
        down_time <= 0;
        // speed <= 0;
        speed <= 2;
    end
    else begin
        if(Q == walk) begin
            y_time <= 0;
            jump_count <= 0;
            down_time <= 0;
            down_count <= 0;
            speed <= 2;
            // speed <= 0;
        end
        if (Q == jump) begin
            down_time <= 0;
            down_count <= 0;
            y_time <= (y_time < Y_TIME[speed]) ? y_time + 1 : Y_TIME[speed];
            if (y_time == Y_TIME[speed]) begin
                y_time <= 0; 
                jump_count <= jump_count + 1;
                y <= (y > 10'b0)? y - 1'b1 : y; 
                if (jump_count < 40) speed <= 2;
                else if (jump_count < 50) speed <= 1;
                else speed <= 0;
            end
        end
        if(Q == down) begin
            jump_count <= 0;
            y_time <= 0;
            down_time <= (down_time < Y_TIME[speed]) ? down_time + 1 : Y_TIME[speed];
            if (down_time == Y_TIME[speed])begin
                down_time <= 0;
                down_count <= down_count + 1;
                if (down_count < 50) speed <= 0;
                // if (down_count < 25) speed <= 0;
                else if (down_count < 60) speed <= 1;
                // else if (down_count < 40) speed <= 1;
                else speed <= 2;
                y <= ( !grounded && y < V_H)? y + 1'b1 : y;
            end
        end
    end
end    

// Send the rgb data out
always @(*) begin
if(~video_on)begin
    rgb_next = 12'h000;
    dope_on = 0;
end
else begin
if (dope_region && data_out !=12'h0f0) begin // if  dope_region and dope is't green background
    rgb_next = data_out;
    dope_on = 1;
end
else begin
    dope_on = 0;
end
end
end
endmodule