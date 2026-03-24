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
  reg[2:0]reset_flag[0:15];
  reg[31:0]command;

  bit rcv_5_ts1, rcv_8_ts1, rcv_8_ts2;
  bit sent_12_ts1, sent_16_ts2;
  int fd,fd2;

    orderset DUT(.clk(clk),
                 .rst(reset),
                 .ltssm_states_h(ltssm_states_h),
	         .command(command),
	         .pipe_tx_data(pipe_tx_data),
	         .ts1_cnt(ts1_sent_cnt),
	         .ts2_cnt(ts2_sent_cnt),
	         .cnt(ts_count),
                 .cnt_reset(reset_flag)
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
  
  always_comb begin
    case(state)
      
      DETECT: begin 
        if(d_to != 100 && rcv_5_ts1) begin//2ms
          next_state=POLLING_ACTIVE;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=1;
	  command=0;
	end
	else if(d_to==100 && !rcv_5_ts1) begin
	  next_state=DETECT;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=0;
	end
	else begin
          next_state=DETECT;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=0;
	end
	  for(int i=0;i<=15;i++)
	    ltssm_states_h[i]=0;
      end
      
      POLLING_ACTIVE: begin
	if(pa_to != 200 && (sent_12_ts1 && rcv_8_ts1)) begin//24ms
          next_state=POLLING_CONFIG;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=2;
	end
	else if(pa_to == 200 && (!sent_12_ts1 || !rcv_8_ts1)) begin
	  next_state=DETECT;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=0;
	end
	else begin
          next_state=POLLING_ACTIVE;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=1;
	end
	  for(int i=0;i<=15;i++)
	    ltssm_states_h[i]=1;
	  command=0;
      end
      
      
       POLLING_CONFIG: begin
	if(pc_to != 300 && (sent_16_ts2 && rcv_8_ts2)) begin//48ms
           next_state=CONFIGURATION;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=3;
	end
	else if(pc_to == 300 && (!sent_16_ts2 || !rcv_8_ts2)) begin
	   next_state=DETECT;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=0;
	end
	else begin
           next_state=POLLING_CONFIG;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=2;
	end
	  for(int i=0;i<=15;i++)
	   ltssm_states_h[i]=2;
	   command=1;
      end
      
       CONFIGURATION: begin
	if(c_to == 200) begin//24ms
           next_state= DETECT;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=0;
        end
	else begin
           next_state=CONFIGURATION;
	  for(int i=0;i<=15;i++)
            reset_flag[i]=3;
	end
	  for(int i=0;i<=15;i++)
	   ltssm_states_h[i]=3;
	   command=1;
      end
      
      default: begin
                 next_state=DETECT;
	         for(int i=0;i<=15;i++)
	         ltssm_states_h[i]=0;
		 command=2;
	       end
    endcase
  end

  always_ff@(posedge clk) begin
    if(ts1_sent_cnt[0]==12)begin
      sent_12_ts1 <= 32'b1;
    end
    else if(ts2_sent_cnt[0]==16) begin
      sent_16_ts2 <= 32'b1;
    end
    else begin
      case(state)
        0: begin
           if(next_state == 1)begin
            sent_12_ts1 <= 0;
            sent_16_ts2 <= 0;
	   end
	end
        1: begin
           if(next_state == 2)begin
            sent_12_ts1 <= 0;
            sent_16_ts2 <= 0;
	   end
	end
        2: begin
           if(next_state == 3)begin
            sent_12_ts1 <= 0;
            sent_16_ts2 <= 0;
	   end
	end
        3: begin
           if(next_state == 0)begin
            sent_12_ts1 <= 0;
            sent_16_ts2 <= 0;
	   end
	end
	default :begin
            sent_12_ts1 <= 0;
            sent_16_ts2 <= 0;
	end
      endcase
    end
  end

  always_ff@(posedge clk) begin
    if(ts1_rcvd_cnt[0]==5)
      rcv_5_ts1 <= 32'b1;
    else if(ts1_rcvd_cnt[0] == 8)
      rcv_8_ts1 <= 32'b1;
    else if(ts2_rcvd_cnt[0]==8)
      rcv_8_ts2 <= 32'b1;
    else begin
      case(state)
        DETECT: begin
           $fdisplay(fd,$sformatf("entered detect state at %0t state:%0d",$time,state));
           if(next_state == 1)begin
            $fdisplay(fd,$sformatf("reset rcv_ts1 det->pol_act at %0t",$time));
            rcv_5_ts1 <= 0;
            rcv_8_ts1 <= 0;
            rcv_8_ts2 <= 0;
	   end
	end
      POLLING_ACTIVE: begin
           $fdisplay(fd,$sformatf("entered polling_active state at %0t state:%0d",$time,state));
           if(next_state == 2)begin
            $fdisplay(fd,$sformatf("reset rcv_ts1 pol_act->pol_cfg at %0t",$time));
            rcv_5_ts1 <= 0;
            rcv_8_ts1 <= 0;
            rcv_8_ts2 <= 0;
	   end
	end
   POLLING_CONFIG: begin
           $fdisplay(fd,$sformatf("entered polling_config state at %0t state:%0d",$time,state));
           if(next_state == 3)begin
            $fdisplay(fd,$sformatf("reset rcv_ts1 pol_cfg->config at %0t",$time));
            rcv_5_ts1 <= 0;
            rcv_8_ts1 <= 0;
            rcv_8_ts2 <= 0;
	   end
	end
   CONFIGURATION: begin
           $fdisplay(fd,$sformatf("entered configuration state at %0t state:%0d",$time,state));
           if(next_state == 0)begin
            $fdisplay(fd,$sformatf("reset rcv_ts1 config->det at %0t",$time));
            rcv_5_ts1 <= 0;
            rcv_8_ts1 <= 0;
            rcv_8_ts2 <= 0;
	   end
	end
	default :begin
            rcv_5_ts1 <= 0;
            rcv_8_ts1 <= 0;
            rcv_8_ts2 <= 0;
	end
     endcase
    end
    //$fclose(fd);
  end


  always_ff@(posedge clk)begin
    if(reset) begin
     ts1_rcvd_cnt[0]<=0;
     ts2_rcvd_cnt[0]<=0;
    end
    else begin
      case(state)
      
      DETECT: begin
          $fdisplay(fd2,$sformatf("entered detect state:%0d at time:%0t",state,$time));
	if(next_state == 1)begin
          $fdisplay(fd2,$sformatf("ts1_rcv_count reset for det->pol_act at time:%0t",$time));
          ts1_rcvd_cnt[0]<=0;
          ts2_rcvd_cnt[0]<=0;
	end
        else if(pipe_rx_data[0] == 16'h4a4a)
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0]+1;
        else if(pipe_rx_data[0] == 16'h4545)
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0]+1;
        else begin
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0];
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0];
        end
      end

      POLLING_ACTIVE: begin
          $fdisplay(fd2,$sformatf("entered pol_active state:%0d at time:%0t",state,$time));
	if(next_state == 2)begin
          $fdisplay(fd2,$sformatf("ts1_rcv_count reset for pol_act->pol_cfg at time:%0t",$time));
          ts1_rcvd_cnt[0]<=0;
          ts2_rcvd_cnt[0]<=0;
	end
        else if(pipe_rx_data[0] == 16'h4a4a)
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0]+1;
        else if(pipe_rx_data[0] == 16'h4545)
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0]+1;
        else begin
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0];
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0];
        end
      end

      POLLING_CONFIG: begin
          $fdisplay(fd2,$sformatf("entered pol_config state:%0d at time:%0t",state,$time));
	if(next_state == 3)begin
          $fdisplay(fd2,$sformatf("ts1_rcv_count reset for pol_cfg->config at time:%0t",$time));
          ts1_rcvd_cnt[0]<=0;
          ts2_rcvd_cnt[0]<=0;
	end
	else if(pipe_rx_data[0] == 16'h4a4a) begin
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0]+1;
        end
	else if(pipe_rx_data[0] == 16'h4545) begin
          $fdisplay(fd2,$sformatf("entered pol_config 2nd if at time:%0t",$time));
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0]+1;
	end
        else begin
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0];
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0];
        end
      end

      CONFIGURATION: begin
          $fdisplay(fd2,$sformatf("entered configuration state:%0d at time:%0t",state,$time));
	if(next_state == 0)begin
          $fdisplay(fd2,$sformatf("ts1_rcv_count reset for config->detect at time:%0t",$time));
          ts1_rcvd_cnt[0]<=0;
          ts2_rcvd_cnt[0]<=0;
	end
	else if(pipe_rx_data[0] == 16'h4a4a) begin
          $fdisplay(fd2,$sformatf("entered configuration 1st if ts1 os check at time:%0t",$time));
          ts1_rcvd_cnt[0]<=ts1_rcvd_cnt[0]+1;
	end
        else if(pipe_rx_data[0] == 16'h4545)
          ts2_rcvd_cnt[0]<=ts2_rcvd_cnt[0]+1;
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

  initial begin
    fd=$fopen("debug.txt","w");
    fd2=$fopen("debug2.txt","w");
  end

endmodule
