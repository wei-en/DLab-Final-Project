`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/26 19:49:29
// Design Name: 
// Module Name: life_rom
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


// last modified : 2020/1/3, kk

module mary_jay_rom
#(parameter DATA_WIDTH = 12, ADDR_WIDTH = 8, ROM_SIZE = 220)
 (input clk,
  input  [ADDR_WIDTH-1 : 0] addr,
  output reg [DATA_WIDTH-1 : 0] data_o);

// declareation of the memory cells
reg [DATA_WIDTH-1 : 0] ROM [ROM_SIZE - 1:0];

// initialize the rom cells with the values defined in .mem file
initial begin
    $readmemh("the_mary_jay.mem", ROM);
end

// read operation
always@(posedge clk) begin
    data_o <= ROM[addr];
end


endmodule
