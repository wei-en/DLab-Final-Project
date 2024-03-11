module dope_rom
#(parameter DATA_WIDTH = 12, ADDR_WIDTH = 20, ROM_SIZE = 400)
 (input clk,
  input  [ADDR_WIDTH-1 : 0] addr,
  output reg [DATA_WIDTH-1 : 0] data_o);
 reg [DATA_WIDTH-1 : 0] ROM [ROM_SIZE - 1:0];


// initialize the rom cells with the values defined in .mem file
initial begin
    $readmemh("chara.mem", ROM);
end

// read operation
always@(posedge clk) begin
    data_o <= ROM[addr];
end


endmodule