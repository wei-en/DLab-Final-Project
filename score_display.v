// last modified : 2019/12/19, zyc

module score_display (
	input wire clk, // system clock
    input wire reset_n,
    input wire [9:0]  score,   // range 0~999
    input wire [9:0]  pixel_x, // x coordinate of the next pixel (between 0 ~ 639)
    input wire [9:0]  pixel_y, // y coordinate of the next pixel (between 0 ~ 479)
    output reg score_region  // 0 or 1, set color in the top module
    );
	
	localparam leftmost_x = 400;
	localparam ceiling_y = 52;
	localparam floor_y = 62;
	localparam NUM_W = 10;

	reg  [9:0] number_addr [0:9]; // the start position of each number
	reg  [9:0] addr;
	wire [9:0] rom_addr; // input to number-rom, max 1000
    wire [11:0] rom_out; // output from number-rom
    wire [9:0] score_bounded;
    assign score_bounded = ( score <= 999 ) ? score : 999;
	//number-rom module here
	number_rom rom1(.clk(clk), .addr(rom_addr), .data_o(rom_out));
	assign rom_addr = addr;

	always @(posedge clk) begin
	    if(~reset_n) begin
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

	reg [9:0] prev_score; // shift-reg for score
	wire update; // if score has changed, update become 1
	always @(posedge clk) begin
	    if(~reset_n)
	       prev_score <= 10'b0;
	    else
		   prev_score <= score_bounded;
	end
	assign update = (prev_score!=score_bounded);


	wire [11:0] bcd_out;
	reg  [11:0] bcd_out_r;
	wire done;
	// binary to bcd
	bin2bcd_serial #( .BINARY_BITS(10), .BCD_DIGITS(3))
		bcd_converter( .clock(clk), .start(update), .binary_in(score_bounded), .bcd_out(bcd_out), .done(done));
    always @(posedge clk)begin
        if(~reset_n)
            bcd_out_r <= 12'b0;
        else if(done)
            bcd_out_r <= bcd_out;
    end

    wire num1_region,num2_region,num3_region;
    assign num1_region = (pixel_x >= leftmost_x && pixel_x < leftmost_x + NUM_W && pixel_y >= ceiling_y && pixel_y < floor_y);
    assign num2_region = (pixel_x >= leftmost_x + NUM_W && pixel_x < leftmost_x + (NUM_W<<1) && pixel_y >= ceiling_y && pixel_y < floor_y);
    assign num3_region = (pixel_x >= leftmost_x + (NUM_W<<1) && pixel_x < leftmost_x + NUM_W*3 && pixel_y >= ceiling_y && pixel_y < floor_y); 
	always @(posedge clk) begin
		if(~reset_n)begin
		  addr <= 10'b0;
        end else begin
            // leftmost number  * _ _
            if(num1_region)
                addr <= number_addr[bcd_out_r[11:8]] + ( pixel_y - ceiling_y )*NUM_W + ( pixel_x - leftmost_x );    
            // number in the middle _ * _
            else if(num2_region)
                addr <= number_addr[bcd_out_r[7:4]] + ( pixel_y - ceiling_y )*NUM_W + ( pixel_x - leftmost_x - NUM_W );   
            // rightmost number _ _ *
            else if(num3_region)
                addr <= number_addr[bcd_out_r[3:0]] + ( pixel_y - ceiling_y )*NUM_W + ( pixel_x - leftmost_x - (NUM_W<<1) );
		end
	end
	
	always @(posedge clk) begin
	    if(rom_out != 12'h0f0) // if not green(transparent)
            score_region <= 1'b1;
	    else
	        score_region <= 1'b0;
	end
	
endmodule