// SINGLE PORT RAM

`ifndef ADDR_WIDTH
	`define ADDR_WIDTH 8
`endif

`ifndef DATA_WIDTH
	`define DATA_WIDTH 8
`endif

`ifndef DEPTH
	`define DEPTH 256
`endif

module RAM(
  input clk, rst,
  input [`ADDR_WIDTH-1:0] addr,
  input [`DATA_WIDTH-1:0] data,
  input wr_rd, // 1->wr, 0->rd
  output reg [`DATA_WIDTH-1:0] data_out
);
  
  reg [`DATA_WIDTH-1:0] ram [0:`DEPTH-1];
  
  integer i;
  
  always@(posedge clk, posedge rst) begin
    if(rst) begin
      data_out <= 0;
      for(i=0; i<`DEPTH; i=i+1) begin
        ram[i] <= 0;
      end
    end
    else begin
      if(wr_rd) begin
        ram[addr] <= data;
      end
      else begin
        data_out <= ram[addr];
      end
    end
  end
  
endmodule
