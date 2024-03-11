
module UI_display(
	input wire clk, // system clock
    input wire reset_n,
    input wire [3:0] stage, // stage index 0(start) ~ 10
    input wire [2:0] life, // life 1~5 (0 -> gameover)
    input wire [9:0]  pixel_x, // x coordinate of the next pixel (between 0 ~ 639)
    input wire [9:0]  pixel_y, // y coordinate of the next pixel (between 0 ~ 479)
    output wire UI_region,
    output reg [11:0] rgb_next
	);
	
	// game region
    localparam UI_leftmost_x = 13; 
    localparam UI_rightmost_x = 627;
    localparam UI_ceiling_y = 80;
    localparam UI_floor_y = 467;    
    // a frame squares out a rectangular region which is the game region
    // so region outside the game region is UI region.
    assign UI_region = ( pixel_x < UI_leftmost_x || pixel_x > UI_rightmost_x )
                    || ( pixel_y < UI_ceiling_y || pixel_y > UI_floor_y );
                    
                    
	// the word "SCORE" position
	localparam score_leftmost_x = 340;
	localparam score_W = 50;
	localparam score_ceiling_y = 32;
	localparam score_floor_y = 42;
	wire score_region;
	assign score_region = ( pixel_x >= score_leftmost_x && pixel_x < score_leftmost_x + score_W )
						&& ( pixel_y >= score_ceiling_y && pixel_y < score_floor_y );

	// "SCORE" rom
	wire [11:0] score_out;
	wire [8:0] score_addr;
	score_rom score_rom1(.clk(clk),
	  				.addr(score_addr),
	  				.data_o(score_out));
	assign score_addr = (score_region) ? ( pixel_y - score_ceiling_y )*score_W + ( pixel_x - score_leftmost_x) : 9'b0;

	// title position
	localparam title_leftmost_x = 50;
	localparam title_W = 22;
	localparam title_ceiling_y = 32;
	localparam title_floor_y = 42;
	wire title_region;
	assign title_region =  ( pixel_x >= title_leftmost_x && pixel_x < title_leftmost_x + title_W )
						&& ( pixel_y >= title_ceiling_y && pixel_y < title_floor_y );
	// title rom
	wire [7:0] title_addr;
	wire [11:0] title_out;
	lab_rom lab_rom2(.clk(clk),
	  				.addr(title_addr),
	  				.data_o(title_out));
	assign title_addr = (title_region) ? ( pixel_y - title_ceiling_y )*title_W + ( pixel_x - title_leftmost_x) : 8'b0001_1011;
	
	// stage number position
	localparam stage_leftmost_x = 74;
	localparam stage_W = 10;
	localparam stage_ceiling_y = 32;
	localparam stage_floor_y = 42;
	wire stage_region;
	assign stage_region =  ( pixel_x >= stage_leftmost_x && pixel_x < stage_leftmost_x + stage_W )
						&& ( pixel_y >= stage_ceiling_y && pixel_y < stage_floor_y );
	// number rom
	reg [9:0] stage_addr;
	reg [3:0] stage_index;
	reg [9:0] number_addr [0:9];
	wire [11:0] stage_out;
	number_rom num_rom3(.clk(clk),
	  				.addr(stage_addr),
	  				.data_o(stage_out));
    
    always @(posedge clk) begin
        if(~reset_n) begin
            stage_index <= 4'b0000;
            stage_addr <= 10'b0;
        end else begin
            stage_index <= ( stage[3:0] <= 9 ) ? stage[3:0] : 4'b0;
            if( stage_region )
                stage_addr <= number_addr[stage_index[3:0]] + ( pixel_y - stage_ceiling_y )*stage_W + ( pixel_x - stage_leftmost_x );
        end
    end
    
    always @(posedge clk) begin
        if(~reset_n)begin
            number_addr[0] <= 10'b0;
            number_addr[1] <= 10'b00_0110_0100;
            number_addr[2] <= 10'b00_1100_1000;
            number_addr[3] <= 10'b01_0010_1100;
            number_addr[4] <= 10'b01_1001_0000;
            number_addr[5] <= 10'b01_1111_0100;
            number_addr[6] <= 10'b10_0101_1000;
            number_addr[7] <= 10'b10_1011_1100;
            number_addr[8] <= 10'b11_0010_0000;
            number_addr[9] <= 10'b11_1000_0100;
        end
    end
	// life (5 hearts) position
	localparam life_leftmost_x = 100;
	localparam life_W = 12;
	localparam life_ceiling_y = 52;
	localparam life_floor_y = 62;
	wire [4:0] life_region;
	assign life_region[4] =  ( pixel_x >= life_leftmost_x && pixel_x < life_leftmost_x + life_W )
						&& ( pixel_y >= life_ceiling_y && pixel_y < life_floor_y );
	assign life_region[3] =  ( pixel_x >= life_leftmost_x + life_W && pixel_x < life_leftmost_x + life_W*2 )
						&& ( pixel_y >= life_ceiling_y && pixel_y < life_floor_y );
	assign life_region[2] =  ( pixel_x >= life_leftmost_x + life_W*2 && pixel_x < life_leftmost_x + life_W*3 )
						&& ( pixel_y >= life_ceiling_y && pixel_y < life_floor_y );
	assign life_region[1] =  ( pixel_x >= life_leftmost_x + life_W*3 && pixel_x < life_leftmost_x + life_W*4 )
						&& ( pixel_y >= life_ceiling_y && pixel_y < life_floor_y );
	assign life_region[0] =  ( pixel_x >= life_leftmost_x + life_W*4 && pixel_x < life_leftmost_x + life_W*5 )
						&& ( pixel_y >= life_ceiling_y && pixel_y < life_floor_y );

	// heart rom
	wire [7:0] life_rom_addr;
	reg [7:0] life_addr;
	localparam life_H = 10;
	wire [11:0] life_out;
	life_rom life_rom4(.clk(clk),
	  			.addr(life_rom_addr),
	  			.data_o(life_out));
	assign life_rom_addr = life_addr;

	always @(posedge clk) begin
		if (life_region[4])
			life_addr <= ((life >= 3'b001) ? life_W*life_H : 0) + (pixel_y - life_ceiling_y)*life_W + pixel_x - life_leftmost_x; 
		else if (life_region[3])
			life_addr <= ((life >= 3'b010) ? life_W*life_H : 0) + (pixel_y - life_ceiling_y)*life_W + pixel_x - life_leftmost_x - life_W*1; 
		else if (life_region[2])
			life_addr <= ((life >= 3'b011) ? life_W*life_H : 0) + (pixel_y - life_ceiling_y)*life_W + pixel_x - life_leftmost_x - life_W*2; 
		else if (life_region[1])
			life_addr <= ((life >= 3'b100) ? life_W*life_H : 0) + (pixel_y - life_ceiling_y)*life_W + pixel_x - life_leftmost_x - life_W*3; 
		else if (life_region[0])
			life_addr <= ((life == 3'b101) ? life_W*life_H : 0) + (pixel_y - life_ceiling_y)*life_W + pixel_x - life_leftmost_x - life_W*4; 
	end

	always @(*) begin
		if(score_region)
			rgb_next = (score_out != 12'h0f0) ? score_out : 12'h444;
		else if(title_region)
			rgb_next = (title_out != 12'h0f0) ? title_out : 12'h444;
		else if(life_region[0]||life_region[1]||life_region[2]||life_region[3]||life_region[4])
			rgb_next = (life_out != 12'h0f0) ? life_out : 12'h444;
		else if(stage_region)
			rgb_next = (stage_out != 12'h0f0) ? stage_out : 12'h444;
		else
			rgb_next = 12'h444; //frame color
	end
	
endmodule