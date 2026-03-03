`include "orderset.sv"
`timescale 1ns/1ps
module ltssm_x(input clk,
             input reset,
             input[15:0]pipe_rx_data[0:15],
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
  reg[2:0]ltssm_states_h[0:15];
  reg[31:0]command;

  int rcv_5_ts1, rcv_8_ts1, rcv_8_ts2;
  int sent_12_ts1, sent_16_ts2;


    orderset DUT(.clk(clk),
                 .rst(reset),
                 .ltssm_states_h(ltssm_states_h),
	         .command(command),
	         .pipe_tx_data(pipe_tx_data),
	         .ts1_cnt(ts1_sent_cnt),
	         .ts2_cnt(ts2_sent_cnt),
	         .cnt(ts_count)
                );
  
  
  always_ff@(posedge clk) begin
    if(reset)
      state<=0;
    else
      state<=next_state;
  end
  
  always_ff@(posedge clk) begin
    if(reset) begin
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
        if(d_to != 100 && /*ts1_rcvd_cnt[0] == 5*/rcv_5_ts1) begin//2ms
          next_state=POLLING_ACTIVE;
	  command=0;
	end
	else if(d_to==100 && /*ts1_rcvd_cnt[0] != 5*/!rcv_5_ts1)
	  next_state=DETECT;
        else
          next_state=DETECT;
	  for(int i=0;i<=15;i++)
	    ltssm_states_h[i]=0;
      end
      
      POLLING_ACTIVE: begin
        if(pa_to != 200 && (/*ts1_sent_cnt[0] == 12*/sent_12_ts1 && /*ts1_rcvd_cnt[0] == 8*/rcv_8_ts1))//24ms
          next_state=POLLING_CONFIG;
	else if(pa_to == 200 && (/*ts1_sent_cnt[0] != 12*/!sent_12_ts1 || /*ts1_rcvd_cnt[0] != 8*/!rcv_8_ts1))
	  next_state=DETECT;
	else
          next_state=POLLING_ACTIVE;
	  for(int i=0;i<=15;i++)
	    ltssm_states_h[i]=1;
	  command=0;
      end
      
      
       POLLING_CONFIG: begin
         if(pc_to != 300 && (/*ts2_sent_cnt[0] == 16*/sent_16_ts2 && /*ts2_rcvd_cnt[0] == 8*/rcv_8_ts2))//48ms
           next_state=CONFIGURATION;
        else if(pc_to == 300 && (/*ts2_sent_cnt[0] != 16*/!sent_16_ts2 || /*ts2_rcvd_cnt[0] != 8*/!rcv_8_ts2))
	   next_state=DETECT;
        else
           next_state=POLLING_CONFIG;
	  for(int i=0;i<=15;i++)
	   ltssm_states_h[i]=2;
	   command=1;
      end
      
       CONFIGURATION: begin
         if(c_to == 200)//24ms
           next_state= DETECT;
        else
           next_state=CONFIGURATION;
	  for(int i=0;i<=15;i++)
	   ltssm_states_h[i]=3;
	   command=2;
      end
      
      default: begin
                 next_state=DETECT;
	         for(int i=0;i<=15;i++)
	         ltssm_states_h[i]=0;
		 command=2;
	       end
    endcase
  end

  always@(*) begin
    if(ts1_sent_cnt[0]==12)
      sent_12_ts1 = 32'b1;
    else if(ts2_sent_cnt[0]==16)
      sent_16_ts2 = 32'b1;
    else begin
      case(state)
        0: begin
           if(next_state == 1)begin
            sent_12_ts1 = 0;
            sent_16_ts2 = 0;
	   end
	end
        1: begin
           if(next_state == 2)begin
            sent_12_ts1 = 0;
            sent_16_ts2 = 0;
	   end
	end
        2: begin
           if(next_state == 3)begin
            sent_12_ts1 = 0;
            sent_16_ts2 = 0;
	   end
	end
        3: begin
           if(next_state == 0)begin
            sent_12_ts1 = 0;
            sent_16_ts2 = 0;
	   end
	end
	default :begin
            sent_12_ts1 = 0;
            sent_16_ts2 = 0;
	end
      endcase
    end
  end

  always@(*) begin
    if(ts1_rcvd_cnt[0]==5)
      rcv_5_ts1 = 32'b1;
    else if(ts1_rcvd_cnt[0] == 8)
      rcv_8_ts1 = 32'b1;
    else if(ts2_rcvd_cnt[0]==8)
      rcv_8_ts2 = 32'b1;
    else begin
      case(state)
        0: begin
           if(next_state == 1)begin
            rcv_5_ts1 = 0;
            rcv_8_ts1 = 0;
            rcv_8_ts2 = 0;
	   end
	end
        1: begin
           if(next_state == 2)begin
            rcv_5_ts1 = 0;
            rcv_8_ts1 = 0;
            rcv_8_ts2 = 0;
	   end
	end
        2: begin
           if(next_state == 3)begin
            rcv_5_ts1 = 0;
            rcv_8_ts1 = 0;
            rcv_8_ts2 = 0;
	   end
	end
        3: begin
           if(next_state == 0)begin
            rcv_5_ts1 = 0;
            rcv_8_ts1 = 0;
            rcv_8_ts2 = 0;
	   end
	end
	default :begin
            rcv_5_ts1 = 0;
            rcv_8_ts1 = 0;
            rcv_8_ts2 = 0;
	end
     endcase
    end

  end


  always_ff@(posedge clk)begin
    if(reset) begin
     ts1_rcvd_cnt[0]<=0;
     ts2_rcvd_cnt[0]<=0;
    end
    else begin
      case(state)
      
      DETECT: begin
        if(pipe_rx_data[0] == 16'h4a4a)
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0]+1;
        else if(pipe_rx_data[0] == 16'h4545)
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0]+1;
	else if(next_state == 1)begin
          ts1_rcvd_cnt[0]<=0;
          ts2_rcvd_cnt[0]<=0;
	end
        else begin
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0];
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0];
        end
      end

      POLLING_ACTIVE: begin
        if(pipe_rx_data[0] == 16'h4a4a)
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0]+1;
        else if(pipe_rx_data[0] == 16'h4545)
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0]+1;
	else if(next_state == 2)begin
          ts1_rcvd_cnt[0]<=0;
          ts2_rcvd_cnt[0]<=0;
	end
        else begin
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0];
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0];
        end
      end

      POLLING_CONFIG: begin
        if(pipe_rx_data[0] == 16'h4a4a)
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0]+1;
        else if(pipe_rx_data[0] == 16'h4545)
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0]+1;
	else if(next_state == 3)begin
          ts1_rcvd_cnt[0]<=0;
          ts2_rcvd_cnt[0]<=0;
	end
        else begin
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0];
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0];
        end
      end

      CONFIGURATION: begin
        if(pipe_rx_data[0] == 16'h4a4a)
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0]+1;
        else if(pipe_rx_data[0] == 16'h4545)
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0]+1;
	else if(next_state == 0)begin
          ts1_rcvd_cnt[0]<=0;
          ts2_rcvd_cnt[0]<=0;
	end
        else begin
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0];
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0];
        end
      end

      default: begin
        ts1_rcvd_cnt[0]<=0;
        ts2_rcvd_cnt[0]<=0;
      end

      endcase
    end
  end

endmodule
