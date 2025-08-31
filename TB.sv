`ifndef ADDR_WIDTH
	`define ADDR_WIDTH 8
`endif

`ifndef DATA_WIDTH
	`define DATA_WIDTH 8
`endif

`ifndef DEPTH
	`define DEPTH 256
`endif

interface single_port_ram_intf;
  
  logic clk, rst;
  logic [`DATA_WIDTH-1:0] data, data_out;
  logic [`ADDR_WIDTH-1:0] addr;
  logic wr_rd;
  
endinterface

class transaction;
  
  int queue[$]; 
  
  rand bit [`DATA_WIDTH-1:0] data;
  bit [`DATA_WIDTH-1:0] data_out;
  rand bit wr_rd;
  rand bit [`ADDR_WIDTH-1:0] addr;
  
  constraint wr_rd_val {
    wr_rd dist {1:=6,0:=4};
  }
  constraint data_range { 
    data inside {[1:10]};
  }
  constraint addr_range {
    wr_rd == 1'b1 -> addr inside {[1:10]};
  }
  
endclass

module tb;
  
  single_port_ram_intf intf();
  
  RAM DUT(intf.clk, intf.rst, intf.addr, intf.data, intf.wr_rd, intf.data_out);
  
  initial begin
    intf.clk <= 1'b0;
  end
  
  always #10 intf.clk <= ~intf.clk;
  
  integer delay;
  
  task reset();
    intf.rst <= 1'b1;
    intf.data <= 0;
    intf.addr <= 0;
    intf.wr_rd <= 0;
    repeat(2)@(posedge intf.clk);
    intf.rst<= 1'b0;
    $display("SYSTEM RESET");
  endtask
  
  reg[7:0] i;
  
  task write();
    repeat(2)@(posedge intf.clk);
    intf.wr_rd <= 1'b1;
    for(i=0; i<10; i++) begin
      @(posedge intf.clk);
      intf.addr <= i;
      intf.data <= $urandom_range(0,255);
      @(posedge intf.clk);
      $display("data:%0d, addr:%0d", intf.data, intf.addr);
    end
    $display("DATA WRITTEN SUCCESSFULLY");
    intf.wr_rd <= 1'b0;
  endtask
  
  task read();
    repeat(2)@(posedge intf.clk);
    //intf.wr_rd <= 1'b0;
    for(i=0; i<10; i++) begin
      //@(posedge intf.clk);
      intf.addr <= i;
      repeat(2)@(posedge intf.clk);
      $display("data_out:%0d, addr:%0d", intf.data_out, intf.addr);
    end
    $display("DATA READ SUCCESSFULLY");
  endtask
  
  int id;
  
  task run(transaction trans);
    
    assert(trans.randomize()) else $error("RANDOMIZATION FAILED");
    if(trans.wr_rd) begin
      intf.wr_rd <= 1'b1;
      intf.data <= trans.data;
      intf.addr <= trans.addr;
      @(posedge intf.clk);
      trans.queue.push_back(intf.addr);
      $display("wr_rd=%0d, data:%0d, addr:%0d", intf.wr_rd, intf.data, intf.addr);
    end
    else begin
      intf.wr_rd <= 1'b0;
      if(trans.queue.size() == 0) begin
        $display("EMPTY READ");
        //$finish();
      end
      else begin
        id = $urandom_range(0,trans.queue.size()-1);
        //$display("id = %0d, trans.queue[id] = %0d", id, trans.queue[id]);
        intf.addr <= trans.queue[id];
        trans.queue.delete(id);
        repeat(2)@(posedge intf.clk);
        $display("wr_rd=%0d, data_out:%0d, addr:%0d", intf.wr_rd, intf.data_out, intf.addr);
      end
    end
    
  endtask
  
  int j;
  
  transaction trans;
  
  initial begin
    
    reset();
    write();
    read();
    trans = new();
    for(j=0; j<15; j++) begin
      run(trans);
    end
    
    $finish();
    
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb);
  end
  
endmodule
