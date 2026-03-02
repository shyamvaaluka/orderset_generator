`include "orderset.sv"
`timescale 1ns/1ps
module ltssm(input clk,
                   rst,
             input[15:0]pipe_rx_data[0:15],
	     input[2:0]ltssm_states_h[0:15],
	     input[31:0]command,
             output reg[15:0]pipe_tx_data[0:15]);
  localparam DETECT=0;
  localparam POLLING_ACTIVE=1;
  localparam POLLING_CONFIG=2;
  localparam CONFIGURATION=3;
  
  reg[31:0]d_to,pa_to,pc_to,c_to;
  reg[1:0]state, next_state;
  
  reg[8*20:1] state_ascii;

  reg[31:0]ts1_sent_cnt[0:15];
  reg[31:0]ts2_sent_cnt[0:15];
  reg[31:0]ts1_rcvd_cnt[0:15];
  reg[31:0]ts2_rcvd_cnt[0:15];
  reg[31:0]ts_count[0:15];

  genvar i;

  generate
    for(i=0;i<=15;i++)begin
    orderset DUT(.clk(clk),
                 .rst(rst),
                 .ltssm_states_h(ltssm_states_h[i]),
	         .command(command),
	         .pipe_tx_data(pipe_tx_data[i]),
	         .pipe_rx_data(pipe_rx_data[i]),
	         .ts1_cnt(ts1_sent_cnt[i]),
	         .ts2_cnt(ts2_sent_cnt[i]),
	         .cnt(ts_count[i])
                );
    end
  endgenerate
  
  
  always_ff@(posedge clk) begin
    if(rst)
      state<=0;
    else
      state<=next_state;
  end
  
  always_ff@(posedge clk) begin
    if(rst) begin
      d_to<=0;
      pa_to<=0;
      pc_to<=0;
      c_to<=0;
    end
    else begin
      case(state)
      DETECT: begin
                d_to++;
                pa_to<=0;
                pc_to<=0;
                c_to<=0;
                state_ascii="detect_state";
      end
      
      POLLING_ACTIVE: begin
                         d_to<=0;
                         pa_to++;
                         pc_to<=0;
                         c_to<=0;
                         state_ascii="polling_active";
      end
      
      
       POLLING_CONFIG: begin
                         d_to<=0;
                         pa_to<=0;
                         pc_to++;
                         c_to<=0;
                         state_ascii="polling_config";
      end
      
       CONFIGURATION: begin
                         d_to<=0;
                         pa_to<=0;
                         pc_to<=0;
                         c_to++;
                         state_ascii="configuration";
      end
      
      default: begin
                 d_to<=0;
                 pa_to<=0;
                 pc_to<=0;
                 c_to<=0;
                 state_ascii="detect_state";
      end
    endcase
    end
  end
  
  always@(*)begin
    case(state)
      
      DETECT: begin 
        if(d_to != 100 && ts1_rcvd_cnt == 5) begin//2ms
          next_state=POLLING_ACTIVE;
	  command=0;
	end
	else if(d_to==100 && ts1_rcvd_cnt != 5)
	  next_state=DETECT;
        else
          next_state=DETECT;
	  ltssm_states_h=0;
      end
      
      POLLING_ACTIVE: begin
        if(pa_to != 200 && (ts1_sent_cnt == 12 && ts2_rcvd_cnt == 8))//24ms
          next_state=POLLING_CONFIG;
	else if(pa_to == 200 && (ts1_sent_cnt != 12 || ts2_rcvd_cnt != 8))
	  next_state=DETECT;
	else
          next_state=POLLING_ACTIVE;
	  ltssm_states_h=1;
	  command=0;
      end
      
      
       POLLING_CONFIG: begin
         if(pc_to != 300 && (ts1_sent_cnt == 16 && ts2_rcvd_cnt == 8))//48ms
           next_state=CONFIGURATION;
        else if(pc_to == 300 && (ts1_sent_cnt != 16 || ts2_rcvd_cnt != 8))
	   next_state=DETECT;
        else
           next_state=POLLING_CONFIG;
	   ltssm_states_h=2;
	   command=1;
      end
      
       CONFIGURATION: begin
         if(c_to == 200)//24ms
           next_state= DETECT;
        else
           next_state=CONFIGURATION;
	   ltssm_states_h=3;
	   command=2;
      end
      
      default: begin
                 next_state=DETECT;
	         ltssm_states_h=0;
		 command=2;
	       end
    endcase
  end


  always_ff@(posedge clk)begin
    if(rst) begin
     ts1_rcvd_cnt<=0;
     ts2_rcvd_cnt<=0;
    end
    else begin
      if(pipe_rx_data[63:48] == 16'h4a4a)
        ts1_rcvd_cnt<=ts1_rcvd_cnt+1;
      else if(pipe_rx_data[63:48] == 16'h4545)
        ts2_rcvd_cnt<=ts2_rcvd_cnt+1;
      else begin
        ts1_rcvd_cnt<=0;
	ts2_rcvd_cnt<=0;
      end
    end
  end
  
endmodule
