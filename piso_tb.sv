module piso_tb;
  reg clk=0;
  reg rst;
  reg[15:0]i0;
  reg[15:0]i1;
  reg[15:0]i2;
  reg[15:0]i3;
  reg load;
  wire[15:0]out;
  wire fifo_full,fifo_empty;

  always #5 clk=~clk;
  piso DUT(.clk(clk),
           .rst(rst),
	   .i0(i0),
	   .i1(i1),
	   .i2(i2),
	   .i3(i3),
	   .load(load),
	   .out(out),
	   .fifo_full(fifo_full),
	   .fifo_empty(fifo_empty));

  task sim(input[15:0]x1,x2,x3,x4);
    @(negedge clk);
    load=1'b1;
    i0=x1;
    i1=x2;
    i2=x3;
    i3=x4;
    @(negedge clk);
    load=1'b0;
  endtask

  initial begin
    rst=1'b1;
    @(negedge clk);
    rst=1'b0;
    sim(16'h4a4a,16'hf7bc,16'h4ef7,16'h307e);
    sim(16'h4545,16'hf7bc,16'h4ef7,16'h307e);
    sim(16'h4a4a,16'hf7bc,16'h30f7,16'h1e7e);
    sim(16'h4545,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4a4a,16'hf7bc,16'h34f7,16'h1d7f);
    sim(16'h4545,16'hf7bc,16'h20f7,16'h1f73);
    sim(16'h4a4a,16'hf7bc,16'hfff7,16'h237e);
    sim(16'h4a4a,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4a4a,16'hf7bc,16'h4ef7,16'h307e);
    sim(16'h4545,16'hf7bc,16'h4ef7,16'h307e);
    sim(16'h4a4a,16'hf7bc,16'h30f7,16'h1e7e);
    sim(16'h4545,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4a4a,16'hf7bc,16'h34f7,16'h1d7f);
    sim(16'h4545,16'hf7bc,16'h20f7,16'h1f73);
    sim(16'h4a4a,16'hf7bc,16'hfff7,16'h237e);
    sim(16'h4a4a,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4a4a,16'hf7bc,16'hfff7,16'h237e);
    sim(16'h4a4a,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4545,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4a4a,16'hf7bc,16'h34f7,16'h1d7f);
    sim(16'h4545,16'hf7bc,16'h20f7,16'h1f73);
    sim(16'h4a4a,16'hf7bc,16'hfff7,16'h237e);
    sim(16'h4a4a,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4a4a,16'hf7bc,16'hfff7,16'h237e);
    sim(16'h4a4a,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4545,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4a4a,16'hf7bc,16'h34f7,16'h1d7f);
    sim(16'h4545,16'hf7bc,16'h20f7,16'h1f73);
    sim(16'h4a4a,16'hf7bc,16'hfff7,16'h237e);
    sim(16'h4a4a,16'hf7bc,16'h2ef7,16'h1f7e);
    sim(16'h4a4a,16'hf7bc,16'hfff7,16'h237e);
    sim(16'h4a4a,16'hf7bc,16'h2ef7,16'h1fff);
    #3000;
    $finish;

  end


endmodule
