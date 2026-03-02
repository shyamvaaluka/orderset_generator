
module ltssm_top;
 
 reg clk=0;
 reg rst;
 reg[15:0]pipe_rx_data[0:15];
 wire[15:0]pipe_tx_data[0:15];

 ltssm DUT(.clk(clk),
           .rst(rst),
	   .pipe_tx_data(pipe_rx_data),
           .pipe_rx_data(pipe_tx_data)
           );
endmodule
