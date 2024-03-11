
module enemy_control(
	input wire clk, // system clock
    input wire reset_n,
    input wire [3:0]  stage, // stage index 0(start) ~ 10
    input wire [9:0]  chara_x, // x coordinate of the character
    input wire [9:0]  chara_y, // y coordinate of the character
    input wire [9:0]  pixel_x, // x coordinate of the next pixel (between 0 ~ 639)
    input wire [9:0]  pixel_y, // y coordinate of the next pixel (between 0 ~ 479)
    output wire [2:0] enemy_region,
    output reg [11:0] rgb_next
	);
    
	localparam UPPER_BOUNDARY = 80;
	localparam LEFT_BOUNDARY = 13;
	localparam RIGHT_BOUNDARY = 627;
	localparam LOWER_BOUNDARY = 467;
	localparam ENEMY_W = 56;
	localparam ENEMY_H = 48;
    localparam CHARA_W = 26;
    localparam CHARA_H = 44;

    reg half_clk;
	always @(posedge clk) begin
		if(~reset_n)
			half_clk <= 1'b0;
		else
			half_clk <= ~half_clk;
	end
    
    reg [31:0] slow_clk;
    always @(posedge clk) begin
        if(~reset_n)
            slow_clk <= 1'b0;
        else
            slow_clk <= (&slow_clk) ? 32'b0 : slow_clk + 1'b1;
    end

	reg [9:0] x_positions [0:3];
	reg [8:0] y_positions [0:3];

	// initial positions of enemy
	always @(posedge clk) begin
		if (~reset_n) begin
			// reset
			x_positions[0] <= 60;
			x_positions[1] <= 180;
			x_positions[2] <= 300;
			x_positions[3] <= 400;

			y_positions[0] <= 100;
			y_positions[1] <= 120;
			y_positions[2] <= 200;
			y_positions[3] <= 400;
		end
	end
	
	reg [1:0] difficulty;
	reg ready;
	reg [27:0] ready_counter;
	reg [3:0] prev_stage;
	wire change_stage;

	always @(posedge clk) begin
		prev_stage <= stage;
	end
	assign change_stage = (prev_stage!=stage);

	//difficulty control
	always @(posedge clk) begin
		if (~reset_n || change_stage) begin
			// reset
			difficulty <= 2'b00;
			ready <= 1'b0;
			ready_counter <= 28'b1011_1110_1011_1100_0010_0000_0000;
		end else begin
			ready <= (ready_counter==0); 
			if( ~ready ) begin
				ready_counter <= ( ready_counter > 0 ) ? ready_counter - 1'b1 : ready_counter;
				difficulty <= 2'b00;
			end else if( stage >= 1 && stage <= 3 )
				difficulty <= 2'b01;
			else if( stage >= 4 && stage <= 6 )
				difficulty <= 2'b10;
			else if( stage >= 7 && stage <= 9 )
				difficulty <= 2'b11;	
		end
	end

	reg [9:0] x_pos_enemy [0:2]; // right side of the image
	reg [9:0] y_pos_enemy [0:2]; // upper side of the image
	reg [9:0] sense_distance_x,sense_distance_y;
	reg y_direction[0:2]; // 0: go up, 1: go down
	wire [2:0] sensed;
	assign sensed[0] = (( x_pos_enemy[0] >= chara_x && x_pos_enemy[0] - chara_x <= sense_distance_x ) || ( x_pos_enemy[0] <= chara_x && chara_x - x_pos_enemy[0] <= sense_distance_x )) &&
                        (( y_pos_enemy[0] >= chara_y && y_pos_enemy[0] - chara_y <= sense_distance_y ) || ( y_pos_enemy[0] <= chara_y && chara_y - y_pos_enemy[0] <= sense_distance_y ));
	assign sensed[1] = (( x_pos_enemy[1] >= chara_x && x_pos_enemy[1] - chara_x <= sense_distance_x ) || ( x_pos_enemy[1] <= chara_x && chara_x - x_pos_enemy[1] <= sense_distance_x )) &&
					(( y_pos_enemy[1] >= chara_y && y_pos_enemy[1] - chara_y <= sense_distance_y ) || ( y_pos_enemy[1] <= chara_y && chara_y - y_pos_enemy[1] <= sense_distance_y ));
	assign sensed[2] = (( x_pos_enemy[2] >= chara_x && x_pos_enemy[2] - chara_x <= sense_distance_x ) || ( x_pos_enemy[2] <= chara_x && chara_x - x_pos_enemy[2] <= sense_distance_x )) &&
					(( y_pos_enemy[2] >= chara_y && y_pos_enemy[2] - chara_y <= sense_distance_y ) || ( y_pos_enemy[2] <= chara_y && chara_y - y_pos_enemy[2] <= sense_distance_y ));

	// behavior control
	always @(posedge clk) begin
		if ( difficulty == 2'b00 ) begin // do not move & set initial position
			if( stage >= 1 && stage <= 3 )begin
				x_pos_enemy[0] <= x_positions[0];
				y_pos_enemy[0] <= y_positions[2];
				y_direction[0] <= 1'b0;

				x_pos_enemy[1] <= x_positions[1];
				y_pos_enemy[1] <= y_positions[1];
				y_direction[1] <= 1'b0;

				x_pos_enemy[2] <= x_positions[3];
				y_pos_enemy[2] <= y_positions[3];
				y_direction[2] <= 1'b0;
				
				sense_distance_x <= 0;
                sense_distance_y <= 0;
			end else if ( stage >= 4 && stage <= 6 )begin
				x_pos_enemy[0] <= x_positions[0];
				y_pos_enemy[0] <= y_positions[1];

				x_pos_enemy[1] <= x_positions[2];
				y_pos_enemy[1] <= y_positions[2];

				x_pos_enemy[2] <= x_positions[3];
				y_pos_enemy[2] <= y_positions[3];
				
				sense_distance_x <= 220;
                sense_distance_y <= 150;
			end else if ( stage >= 7 && stage <= 9 )begin
				x_pos_enemy[0] <= x_positions[0];
				y_pos_enemy[0] <= y_positions[0];

				x_pos_enemy[1] <= x_positions[1];
				y_pos_enemy[1] <= y_positions[2];

				x_pos_enemy[2] <= x_positions[3];
				y_pos_enemy[2] <= y_positions[3];
				
				sense_distance_x <= 280;
                sense_distance_y <= 200;
			end
		end else if ( difficulty == 2'b01 && &slow_clk[22:0] )begin //simple behavior, do not follow charcter
            
            if(y_pos_enemy[0] >= y_positions[2] + ENEMY_H)
                y_direction[0] <= 1'b0;
            else if (y_pos_enemy[0] <= y_positions[2] - ENEMY_H)
                y_direction[0] <= 1'b1;

			x_pos_enemy[0] <= ( x_pos_enemy[0] > 10'b00_0000_1101 ) ? x_pos_enemy[0] - 1'b1 : RIGHT_BOUNDARY + ENEMY_W;
			y_pos_enemy[0] <= ( y_direction[0] ) ? y_pos_enemy[0] + 1'b1 : y_pos_enemy[0] - 1'b1;

			if(y_pos_enemy[1] >= y_positions[1] + ENEMY_H)
                y_direction[1] <= 1'b0;
            else if (y_pos_enemy[1] <= y_positions[1] - ENEMY_H)
                y_direction[1] <= 1'b1;
                                
			x_pos_enemy[1] <= ( x_pos_enemy[1] < RIGHT_BOUNDARY + ENEMY_W ) ? x_pos_enemy[1] + 1'b1 : 10'b00_0000_1101;
			y_pos_enemy[1] <= ( y_direction[1] ) ? y_pos_enemy[1] + 1'b1 : y_pos_enemy[1] - 1'b1;

			if(y_pos_enemy[2] >= y_positions[3] + ENEMY_H)
				y_direction[2] <= 1'b0;
		    else if (y_pos_enemy[2] <= y_positions[3] - ENEMY_H)
		        y_direction[2] <= 1'b1;
		        
			x_pos_enemy[2] <= ( x_pos_enemy[2] > 10'b00_0000_1101 ) ? x_pos_enemy[2] - 1'b1 : RIGHT_BOUNDARY + ENEMY_W;
			y_pos_enemy[2] <= ( y_direction[2] ) ? y_pos_enemy[2] + 1'b1 : y_pos_enemy[2] - 1'b1;
		end else if ( difficulty == 2'b10 && &slow_clk[22:0] && |(sensed) )begin // same speed as 01, but follow character
			x_pos_enemy[0] <= (~sensed[0]) ? x_pos_enemy[0] : ( x_pos_enemy[0] > chara_x - 13 ) ? x_pos_enemy[0] - 1'b1 : x_pos_enemy[0] + 1'b1;
			y_pos_enemy[0] <= (~sensed[0]) ? y_pos_enemy[0] : ( y_pos_enemy[0] > chara_y + 22 ) ? y_pos_enemy[0] - 1'b1 : y_pos_enemy[0] + 1'b1;

			x_pos_enemy[1] <= (~sensed[1]) ? x_pos_enemy[1] : ( x_pos_enemy[1] > chara_x - 13 ) ? x_pos_enemy[1] - 1'b1 : x_pos_enemy[1] + 1'b1;
			y_pos_enemy[1] <= (~sensed[1]) ? y_pos_enemy[1] : ( y_pos_enemy[1] > chara_y + 22 ) ? y_pos_enemy[1] - 1'b1 : y_pos_enemy[1] + 1'b1;

			x_pos_enemy[2] <= (~sensed[2]) ? x_pos_enemy[2] : ( x_pos_enemy[2] > chara_x - 13 ) ? x_pos_enemy[2] - 1'b1 : x_pos_enemy[2] + 1'b1;
			y_pos_enemy[2] <= (~sensed[2]) ? y_pos_enemy[2] : ( y_pos_enemy[2] > chara_y + 22 ) ? y_pos_enemy[2] - 1'b1 : y_pos_enemy[2] + 1'b1;
		end else if ( difficulty == 2'b11 && &slow_clk[21:0] && |(sensed) )begin // follow character with higher speed
			x_pos_enemy[0] <= (~sensed[0]) ? x_pos_enemy[0] : ( x_pos_enemy[0] > chara_x - 13 ) ? x_pos_enemy[0] - 1'b1 : x_pos_enemy[0] + 1'b1;
            y_pos_enemy[0] <= (~sensed[0]) ? y_pos_enemy[0] : ( y_pos_enemy[0] > chara_y + 22 ) ? y_pos_enemy[0] - 1'b1 : y_pos_enemy[0] + 1'b1;
        
            x_pos_enemy[1] <= (~sensed[1]) ? x_pos_enemy[1] : ( x_pos_enemy[1] > chara_x - 13 ) ? x_pos_enemy[1] - 1'b1 : x_pos_enemy[1] + 1'b1;
            y_pos_enemy[1] <= (~sensed[1]) ? y_pos_enemy[1] : ( y_pos_enemy[1] > chara_y + 22 ) ? y_pos_enemy[1] - 1'b1 : y_pos_enemy[1] + 1'b1;
        
            x_pos_enemy[2] <= (~sensed[2]) ? x_pos_enemy[2] : ( x_pos_enemy[2] > chara_x - 13 ) ? x_pos_enemy[2] - 1'b1 : x_pos_enemy[2] + 1'b1;
            y_pos_enemy[2] <= (~sensed[2]) ? y_pos_enemy[2] : ( y_pos_enemy[2] > chara_y + 22 ) ? y_pos_enemy[2] - 1'b1 : y_pos_enemy[2] + 1'b1;
		end
	end
    
	// enemy image region
	assign enemy_region[0] = ( pixel_x + ENEMY_W >= x_pos_enemy[0] && pixel_x < x_pos_enemy[0] && pixel_y >= y_pos_enemy[0] && pixel_y < y_pos_enemy[0] + ENEMY_H );
	assign enemy_region[1] = ( pixel_x + ENEMY_W >= x_pos_enemy[1] && pixel_x < x_pos_enemy[1] && pixel_y >= y_pos_enemy[1] && pixel_y < y_pos_enemy[1] + ENEMY_H );
	assign enemy_region[2] = ( pixel_x + ENEMY_W >= x_pos_enemy[2] && pixel_x < x_pos_enemy[2] && pixel_y >= y_pos_enemy[2] && pixel_y < y_pos_enemy[2] + ENEMY_H );

	// enemy rom 56*48*4
	wire [13:0] enemy_rom_addr_0;
	wire [13:0] enemy_rom_addr_1;
	wire [13:0] enemy_rom_addr_2;
	reg [13:0]  enemy_addr[0:2];
	reg [13:0]  enemy_image_index[0:3];
	reg [1:0]   enemy_clock[0:2]; // control image
	wire [11:0] enemy_out_0;
	wire [11:0] enemy_out_1;
	wire [11:0] enemy_out_2;

	enemy_rom enemy_rom0(.clk(clk),
	  			.addr(enemy_rom_addr_0),
	  			.data_o(enemy_out_0));
	enemy_rom enemy_rom1(.clk(clk),
	  			.addr(enemy_rom_addr_1),
	  			.data_o(enemy_out_1));
	enemy_rom enemy_rom2(.clk(clk),
	  			.addr(enemy_rom_addr_2),
	  			.data_o(enemy_out_2));

	assign enemy_rom_addr_0 = enemy_addr[0];
	assign enemy_rom_addr_1 = enemy_addr[1];
	assign enemy_rom_addr_2 = enemy_addr[2];

	// position of each image
	always @(posedge clk) begin
		if (~reset_n) begin
			// reset
			enemy_image_index[0] <= 14'b0; //open eye 0
			enemy_image_index[1] <= 14'b00_1010_1000_0000; //open eye 1
			enemy_image_index[2] <= 14'b01_0101_0000_0000; //close eye 0
			enemy_image_index[3] <= 14'b01_1111_1000_0000; //close eye 1
		end
	end
	// animation control
	always @(posedge clk) begin
		if (~reset_n) begin
			// reset
			enemy_clock[0] <= 2'b0;
		end
		else if (sensed[0] && &slow_clk[24:0] ) begin // open eye -> 0 or 1
			enemy_clock[0] <= (enemy_clock[0] != 2'b0) ? 2'b0 : 2'b01;
		end else if ( &slow_clk[24:0] ) begin // close eye -> 2 or 3
			enemy_clock[0] <= (enemy_clock[0] != 2'b10) ? 2'b10 : 2'b11;
		end
	end
	// animation control
	always @(posedge clk) begin
		if (~reset_n) begin
			// reset
			enemy_clock[1] <= 2'b0;
		end
		else if (sensed[1] && &slow_clk[24:0] ) begin // open eye -> 0 or 1
			enemy_clock[1] <= (enemy_clock[1] != 2'b0) ? 2'b0 : 2'b01;
		end else if ( &slow_clk[24:0] ) begin // close eye -> 2 or 3
			enemy_clock[1] <= (enemy_clock[1] != 2'b10) ? 2'b10 : 2'b11;
		end
	end
	// animation control
	always @(posedge clk) begin
		if (~reset_n) begin
			// reset
			enemy_clock[2] <= 2'b0;
		end
		else if (sensed[2] && &slow_clk[24:0] ) begin // open eye -> 0 or 1
			enemy_clock[2] <= (enemy_clock[2] != 2'b0) ? 2'b0 : 2'b01;
		end else if ( &slow_clk[24:0] ) begin // close eye -> 2 or 3
			enemy_clock[2] <= (enemy_clock[2] != 2'b10) ? 2'b10 : 2'b11;
		end
	end

	// rom control
	always @(posedge clk) begin
		if (~reset_n) begin
			// reset
			enemy_addr[0] <= 14'b0;
			enemy_addr[1] <= 14'b0;
			enemy_addr[2] <= 14'b0;
		end
		else begin
			if(enemy_region[0])
				enemy_addr[0] <= enemy_image_index[enemy_clock[0]] + ( pixel_y - y_pos_enemy[0] )*ENEMY_W + pixel_x + ENEMY_W - x_pos_enemy[0];
			
			if(enemy_region[1])
				enemy_addr[1] <= enemy_image_index[enemy_clock[1]] + ( pixel_y - y_pos_enemy[1] )*ENEMY_W + pixel_x + ENEMY_W - x_pos_enemy[1];	

			if(enemy_region[2])
				enemy_addr[2] <= enemy_image_index[enemy_clock[2]] + ( pixel_y - y_pos_enemy[2] )*ENEMY_W + pixel_x + ENEMY_W - x_pos_enemy[2];	
		end
	end

	//rgb_next control
	always @(posedge clk) begin
		if (~reset_n) begin
			// reset
			rgb_next <= 12'h000;
		end
		else begin
			if(enemy_region[0])
				rgb_next <= (enemy_out_0 != 12'h0f0) ? enemy_out_0 : (enemy_region[1] && enemy_out_1 != 12'h0f0) ? enemy_out_1 : (enemy_region[2] && enemy_out_2 != 12'h0f0) ? enemy_out_2 : 12'h0f0;
			else if (enemy_region[1])
				rgb_next <= (enemy_out_1 != 12'h0f0) ? enemy_out_1 : (enemy_region[2] && enemy_out_2 != 12'h0f0) ? enemy_out_2 : 12'h0f0;
			else if (enemy_region[2])
				rgb_next <= enemy_out_2;
		end
	end
endmodule
