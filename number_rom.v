// last modified : 2019/12/19, zyc

module number_rom
#(parameter DATA_WIDTH = 12, ADDR_WIDTH = 10, ROM_SIZE = 1000)
 (input clk,
  input  [ADDR_WIDTH-1 : 0] addr,
  output reg [DATA_WIDTH-1 : 0] data_o);

// declareation of the memory cells
reg [DATA_WIDTH-1 : 0] ROM [ROM_SIZE - 1:0];


// initialize the rom cells with the values defined in .mem file
initial begin
    $readmemh("number.mem", ROM);
end

// read operation
always@(posedge clk) begin
    data_o <= ROM[addr];
end


endmodule