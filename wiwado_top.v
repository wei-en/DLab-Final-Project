// last modified : 2019/12/19, zyc

module wiwado_top(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    input  [3:0] usr_sw,
    output [3:0] usr_led,
    input uart_rx,
    input uart_tx,
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// ------------------------------------------------------------------------
// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel

vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider #(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;
// end of VGA control signals
// ------------------------------------------------------------------------
// score display controller
wire [9:0] score;
wire [9:0] score_dip;
wire score_region;

score_display sd0(
	.clk(clk), // system clock
    .reset_n(reset_n),
    .score(score),   // range 0~999
    .pixel_x(pixel_x), // x coordinate of the next pixel (between 0 ~ 639)
    .pixel_y(pixel_y), // y coordinate of the next pixel (between 0 ~ 479)
    .score_region(score_region)  // 0 or 1, set color in the top module
    );
// end of score display controller
// ------------------------------------------------------------------------
// UI display controller
wire UI_region;
wire [3:0] stage;
wire [2:0] life;
wire [11:0] rgb_ui_next;
UI_display UI0(.clk(clk), // system clock
           .reset_n(reset_n),
           .stage(stage), // stage index 0(start) ~ 10
           .life(life), // life 1~5 (0 -> gameover)
           .pixel_x(pixel_x), // x coordinate of the next pixel (between 0 ~ 639)
           .pixel_y(pixel_y), // y coordinate of the next pixel (between 0 ~ 479)
           .UI_region(UI_region),
           .rgb_next(rgb_ui_next)
           );
// end of UI display controller
// ------------------------------------------------------------------------
wire U,L,R;
move_uart uart0(.clk(clk),.reset_n(reset_n),.uart_rx(uart_rx),
    .uart_tx(uart_tx),  
    .U(U), 
    .L(L), 
    .R(R));
/*-----------------------------------------------------------------------*/
// for dope
wire grounded;
wire jump;
wire [11:0] rgb_dope;
//wire dir;
wire [9:0] dope_x;
wire [9:0] dope_y;
wire dope_on;

dope dope0(
    .clk(clk),.reset(reset_n),
	  .U(U), .L(L), .R(R),
	  .grounded(grounded),
	  .stage(stage),
	  .pixel_x(pixel_x),
	  .pixel_y(pixel_y),
	  .video_on(video_on),
	  .dope_x(dope_x), 
	  .dope_y(dope_y),	
	  //.direction(dir),	// left = 0 ; right = 1
	  .d_jump(jump),
	  .rgb_next(rgb_dope),
	  .dope_on(dope_on)
);
// ------------------------------------------------------------------------           
// floor display controller
wire [3:0] level;
wire floor_region;
wire [11:0] rgb_floor_next;
assign level = stage;

floor sd_f0(
	.clk(clk), // system clock
    .reset_n(reset_n),
    .level(level),
    .pixel_x(pixel_x), // x coordinate of the next pixel (between 0 ~ 639)
    .pixel_y(pixel_y), // y coordinate of the next pixel (between 0 ~ 479)
    .dope_x(dope_x),
    .dope_y(dope_y +88),
    .jump(jump),
    .grounded(grounded),
    .floor_region(floor_region),  // 0 or 1
    .rgb_next(rgb_floor_next)
    );
// end of floor display controller
// ------------------------------------------------------------------------           
// enemy contrller
reg [9:0] chara_x = 10'b0;
reg [9:0] chara_y = 10'b0;
wire [2:0] enemy_region;
wire [11:0] rgb_enemy_next;

enemy_control enemy_ctrl0(
	.clk(clk), // system clock
    .reset_n(reset_n),
    .stage(stage), // stage index 0(start) ~ 10
    .chara_x(dope_x), // x coordinate of the character
    .chara_y(dope_y), // y coordinate of the character
    .pixel_x(pixel_x), // x coordinate of the next pixel (between 0 ~ 639)
    .pixel_y(pixel_y), // y coordinate of the next pixel (between 0 ~ 479)
    .enemy_region(enemy_region),
    .rgb_next(rgb_enemy_next)
	);
// end of enemy controll
// ------------------------------------------------------------------------
// ------------------------------------------------------------------------
// food (error/warning) display controller
wire error1_region, error2_region, warning_region;
wire [11:0] rgb_error1_next, rgb_error2_next, rgb_warning_next;
wire eaten_error1, eaten_error2, eaten_warning;
assign eaten_error1 = dope_on && error1_region;
assign eaten_error2 = dope_on && error2_region;
assign eaten_warning = dope_on && warning_region;

food #(.name("error.mem"), .idx(3) )error1(
	.clk(clk), // system clock
    .reset_n(reset_n),
    .eaten_n(eaten_error1),
    .level(stage),
    .pixel_x(pixel_x), // x coordinate of the next pixel (between 0 ~ 639)
    .pixel_y(pixel_y), // y coordinate of the next pixel (between 0 ~ 479)
    .food_region(error1_region),  // 0 or 1
    .rgb_next(rgb_error1_next)
    );
food #(.name("error_ano.mem"), .idx(1) )error2(
	.clk(clk), // system clock
    .reset_n(reset_n),
    .eaten_n(eaten_error2),
    .level(stage),
    .pixel_x(pixel_x), // x coordinate of the next pixel (between 0 ~ 639)
    .pixel_y(pixel_y), // y coordinate of the next pixel (between 0 ~ 479)
    .food_region(error2_region),  // 0 or 1
    .rgb_next(rgb_error2_next)
    );
food #(.name("warning.mem"), .idx(2) )warning(
	.clk(clk), // system clock
    .reset_n(reset_n),
    .eaten_n(eaten_warning),
    .level(stage),
    .pixel_x(pixel_x), // x coordinate of the next pixel (between 0 ~ 639)
    .pixel_y(pixel_y), // y coordinate of the next pixel (between 0 ~ 479)
    .food_region(warning_region),  // 0 or 1
    .rgb_next(rgb_warning_next)
    );



// end of food display controller
// ------------------------------------------------------------------------
// life controller
wire gameover;

life_control life_control0(
    .clk(clk),
    .reset_n(reset_n),
    .usr_sw3(usr_sw[3]),
    .stage(stage),
    .chara_y(dope_y),
    .chara_region(dope_on),
    .enemy_region(enemy_region),
    .life(life),
    .gameover(gameover)
    );

// end of life controller
// ------------------------------------------------------------------------     
// start / gameover / win display controller

reg [14:0] start_addr;   //320*240/4 = 19200 < 2^16 -> 15 bit
wire [11:0] start_out;

// mary_jay_rom #(.DATA_WIDTH(12), .ADDR_WIDTH(17), .ROM_SIZE(76800))
mary_jay_rom #(.DATA_WIDTH(12), .ADDR_WIDTH(15), .ROM_SIZE(19200))
    mary_j (.clk(clk), .addr(start_addr), .data_o(start_out));
always @ (posedge clk) begin
  if(~reset_n) start_addr <= 0;
  else begin
    start_addr<= (pixel_y >> 2) * 160 + (pixel_x >> 2);
  end
end

//gameover image

reg [15:0] gameover_addr;   //320*240 =76800 < 2^17
wire [11:0] gameover_out;
gameover_rom #(.DATA_WIDTH(12), .ADDR_WIDTH(15), .ROM_SIZE(19200))
   gameover_mod(.clk(clk), .addr(gameover_addr), .data_o(gameover_out));
always @ (posedge clk) begin
  if(~reset_n) gameover_addr<=0;
  else begin
    gameover_addr<= (pixel_y >> 2) * 160 + (pixel_x >> 2);
  end
end

// win anime
//clear_2.mem: 38400
reg [15:0] clear_addr;   //320*240*2 =38400*2 < 2^17
wire [12:0] clear_out;
reg [15:0] clear_pixel [1:0];   
reg [31:0] clear_clk;
clear_rom #(.DATA_WIDTH(12), .ADDR_WIDTH(16), .ROM_SIZE(38400))
    clear_mod (.clk(clk), .addr(clear_addr), .data_o(clear_out));
initial begin
    clear_pixel[0] = 16'b0;
    clear_pixel[1] = 19200;
end
always @(posedge clk) begin
    if (~reset_n) clear_clk <= 0;
    else clear_clk <= (clear_clk[31:21]>320) ? 0 : clear_clk + 1;
end

always @(posedge clk) begin
    if (~reset_n) begin
        clear_addr <= 0;
    end
    else if (stage > 9) clear_addr <= (clear_pixel[clear_clk[23]]
                                                   + (pixel_y >> 2) * 160 + (pixel_x >> 2));
end
// ------------------------------------------------------------------------     
// stage and score controller
wire landa_region;
wire [11:0] landa_out;
stage_control stage_control0(
    .clk(clk),
    .reset_n(reset_n),
    .gameover(gameover),
    .usr_sw0(usr_sw[0]),
    .eaten_error1(eaten_error1),
    .eaten_error2(eaten_error2),
    .eaten_warning(eaten_warning),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .landa_region_out(landa_region),
    .rgb_next(landa_out),
    .score(score),
    .stage(stage)
    );
// end of stage and score controller
// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end        
// ------------------------------------------------------------------------



always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else begin
    if(stage == 0)
      rgb_next = (start_out == 12'h0f0)?12'h000:start_out;
//   if (stage > 9)
    else if (stage > 9)
        //rgb_next = 12'h0f0; 
        rgb_next = clear_out;
    else if (gameover)
        rgb_next = (gameover_out==12'h0f0) ? 12'h000 : gameover_out;
    //else if (gameover)  rgb_next = 12'h0f0;
    else if(score_region)
        rgb_next = 12'hfff; // white
    else if(UI_region)
        rgb_next = rgb_ui_next;
    else if(landa_region)
        rgb_next = landa_out;
    else if(dope_on)
        rgb_next = rgb_dope;
    else if(|(enemy_region) && rgb_enemy_next != 12'h0f0)
        rgb_next = rgb_enemy_next;
    else if(error1_region)
        rgb_next = rgb_error1_next;
    else if(error2_region)
        rgb_next = rgb_error2_next;
    else if(warning_region)
        rgb_next = rgb_warning_next;
    else if(floor_region)
        rgb_next = rgb_floor_next;
    else
        rgb_next = 12'hAAA; // background
  end
end

// End of the video data display code.
// ------------------------------------------------------------------------

//assign usr_led[3] = grounded;
//assign usr_led[2] = stage[2];
//assign usr_led[1] = stage[1];
assign usr_led[0] = gameover;
//assign usr_led = {grounded,jump, 2'b00};

endmodule