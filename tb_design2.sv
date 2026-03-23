`timescale 1ns/1ps
module ltssm_top_2;
 
 reg clk=0;
 reg reset;
 reg[15:0]pipe_rx_data[0:15];
 logic[15:0]pipe_tx_data[0:15];
 event ev,ev2;
 int c_to_tb;

 bit[15:0]ts1_send_cnt[0:15];
 bit[15:0]ts2_send_cnt[0:15];
 bit[15:0]ts1_rcv_cnt[0:15];
 bit[15:0]ts2_rcv_cnt[0:15];
 bit[8*20:0]state_ascii_tb;
 int ts1_sent_cnt,ts1_rcvd_cnt;
 int ts2_sent_cnt,ts2_rcvd_cnt;
 bit flag_detect,flag_pol_active_send,flag_pol_active_receive,flag_pol_config_send,flag_pol_config_receive;
 int fd_3;
 int l;
 int tracker_pl;

 string tx_sym0[16],tx_sym1[16],tx_sym2[16],tx_sym3[16],tx_sym4[16],tx_sym5[16],tx_sym6[16],tx_sym7[16];
 string rx_sym0[16],rx_sym1[16],rx_sym2[16],rx_sym3[16],rx_sym4[16],rx_sym5[16],rx_sym6[16],rx_sym7[16];

 ltssm_x DUT(.clk(clk),
           .reset(reset),
	   .pipe_tx_data(pipe_rx_data),
           .pipe_rx_data(pipe_tx_data)
           );
always #5 clk=~clk;

  task send_ts1;
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h4a4a;
    end
    @(negedge clk);
     for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'hf7bc;
    end
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h4ef7;
    end
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h307e;
    end

  endtask

  task send_ts2;
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h4545;
    end
    @(negedge clk);
     for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'hf7bc;
    end
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h4ef7;
    end
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h327e;
    end
  endtask

  initial begin
    fd_3=$fopen("state_trans.txt","w");
    tracker_pl=$fopen("tracker_pl","w");    
    $fdisplay(tracker_pl,"-----------------------------TX------------------------------------------------------------------------------RX------------------------------------------------------");
    reset=1;
    @(negedge clk);
    reset=0;
    $fdisplay(tracker_pl,"%0tns                                                                                                                                                                               ltssm in DETECT",$time);	           
    #5;

    fork
      begin	  
        forever begin
          fork	    
            begin//Timeout thread for states in tb begin
              forever begin
                @(negedge clk);		
                if(state_ascii_tb == "CONFIGURATION") begin
                  c_to_tb++;	  
                  if(c_to_tb == 200) begin
                    state_ascii_tb="DETECT";
                    c_to_tb=0;
                    ts1_send_cnt[0]=0;
                    ts2_send_cnt[0]=0;
		    ts1_sent_cnt=0;
		    ts2_sent_cnt=0;
                  end
		  if(pipe_rx_data[0]==16'h4a4a)
	           ts1_rcvd_cnt++;
	          if(pipe_rx_data[0]==16'h4545)
	           ts2_rcvd_cnt++;
               end
              end
            end//Timeout thread for states in tb begin	      

            begin//outer thread-0 begin
              @(negedge clk);
              forever begin
                if(state_ascii_tb=="DETECT" || state_ascii_tb=="POL_ACTIVE") begin
                  send_ts1();
                  ts1_send_cnt[0]++;
		  ts1_sent_cnt++;
                end
                else if(state_ascii_tb=="POL_CONFIG") begin
                  send_ts2();
                  ts2_send_cnt[0]++;
		  ts2_sent_cnt++;
                end
                else if(state_ascii_tb=="CONFIGURATION") begin
                  send_ts1();
		  ts1_sent_cnt++;
                end
              end
              $display("Thread-0 completed at time:%0tns",$time);
            end//outer thread-0 end

            begin//outer thread-1 begin
              forever begin
                @(negedge clk);
                state_ascii_tb="DETECT";
                if(ts1_send_cnt[0]==5) begin
                  @(negedge clk);		  
                  ts1_send_cnt[0]=0;
                  flag_detect=1;
                end
                if(flag_detect==1)
                  break;
              end
              forever begin
                @(negedge clk);
                wait(state_ascii_tb=="POL_ACTIVE");
                if(ts1_send_cnt[0]==16) begin
                  @(negedge clk);
                  ts1_send_cnt[0]=0;
                  flag_pol_active_send=1;
                end
                if(flag_pol_active_send==1)
                 break;
              end
              
              
              forever begin
                @(negedge clk);
                wait(state_ascii_tb=="POL_CONFIG");
                if(ts2_send_cnt[0]==16) begin
                  @(negedge clk);
                  ts2_send_cnt[0]=0;
                  flag_pol_config_send=1;
                end
                if(flag_pol_config_send==1)
                 break;
              end
              #9000;
              $display("Thread-1 completed at time:%0tns",$time);
            end//outer thread-1 end

            begin//outer thread-2 begin
              forever begin
                @(negedge clk);
                wait(state_ascii_tb=="POL_ACTIVE");
		if(pipe_rx_data[0]==16'h4545)
	         ts2_rcvd_cnt++;
                if(pipe_rx_data[0]==16'h4a4a) begin
                  ts1_rcv_cnt[0]++;
		  ts1_rcvd_cnt++;
                end
                if(ts1_rcv_cnt[0]==8) begin
                  @(negedge clk);
                  ts1_rcv_cnt[0]=0;
                  flag_pol_active_receive=1;
                end
                if(flag_pol_active_receive==1)
                 break;
              end
              
              forever begin
                @(negedge clk);
                wait(state_ascii_tb=="POL_CONFIG");
		if(pipe_rx_data[0]==16'h4a4a)
		  ts1_rcvd_cnt++;
                if(pipe_rx_data[0]==16'h4545) begin
                  ts2_rcv_cnt[0]++;
		  ts2_rcvd_cnt++;
                end
                if(ts2_rcv_cnt[0]==8) begin
                  @(negedge clk);
                  ts2_rcv_cnt[0]=0;
                  flag_pol_config_receive=1;
                end
                if(flag_pol_config_receive==1)
                 break;
              end
              wait(ev.triggered);
              $display("Thread-2 completed at time:%0tns",$time);
            end//outer thread-2 end

            
            begin//outer thread-3 begin
              forever begin
                @(negedge clk);
                if(flag_detect==1) begin
                  $fdisplay(fd_3,$sformatf("Enetered the flag_detect state at : %0tns",$time));
                  state_ascii_tb = "POL_ACTIVE";
                  flag_detect=0;
		  ts1_sent_cnt=0;
		  ts1_rcvd_cnt=0;
		  ts2_sent_cnt=0;
		  ts2_rcvd_cnt=0;
                end
                else if(flag_pol_active_send && flag_pol_active_receive) begin
                  $fdisplay(fd_3,$sformatf("Enetered the flag_pol_active state at : %0tns",$time));
                  @(negedge clk);		  
                  state_ascii_tb="POL_CONFIG";
                  flag_pol_active_send=0;
                  flag_pol_active_receive=0;
		  ts1_sent_cnt=0;
		  ts1_rcvd_cnt=0;
		  ts2_sent_cnt=0;
		  ts2_rcvd_cnt=0;
                end
                else if(flag_pol_config_send && flag_pol_config_receive) begin
                  $fdisplay(fd_3,$sformatf("Enetered the configuration state at : %0tns",$time));
                  @(negedge clk);
                  state_ascii_tb="CONFIGURATION";
                  flag_pol_config_send=0;
                  flag_pol_config_receive=0;
		  ts1_sent_cnt=0;
		  ts1_rcvd_cnt=0;
		  ts2_sent_cnt=0;
		  ts2_rcvd_cnt=0;
                  repeat(210)
                    @(negedge clk);
                    ->ev;
                end 

              end
              $display("Thread-3 completed at time:%0tns",$time);
            end//outer thread-3 end

            begin//Tracker thread 1 begin
		repeat(4)
		  @(posedge clk);
		  @(posedge clk);
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s  |  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s                                                                 ",$time,tx_sym0[0],tx_sym0[1],tx_sym0[2],tx_sym0[3],tx_sym0[4],tx_sym0[5],tx_sym0[6],tx_sym0[7],tx_sym0[8],tx_sym0[9],tx_sym0[10],tx_sym0[11],tx_sym0[12],tx_sym0[13],tx_sym0[14],tx_sym0[15],rx_sym0[0],rx_sym0[1],rx_sym0[2],rx_sym0[3],rx_sym0[4],rx_sym0[5],rx_sym0[6],rx_sym0[7],rx_sym0[8],rx_sym0[9],rx_sym0[10],rx_sym0[11],rx_sym0[12],rx_sym0[13],rx_sym0[14],rx_sym0[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s  |  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s                                                                ",$time,tx_sym1[0],tx_sym1[1],tx_sym1[2],tx_sym1[3],tx_sym1[4],tx_sym1[5],tx_sym1[6],tx_sym1[7],tx_sym1[8],tx_sym1[9],tx_sym1[10],tx_sym1[11],tx_sym1[12],tx_sym1[13],tx_sym1[14],tx_sym1[15],rx_sym1[0],rx_sym1[1],rx_sym1[2],rx_sym1[3],rx_sym1[4],rx_sym1[5],rx_sym1[6],rx_sym1[7],rx_sym1[8],rx_sym1[9],rx_sym1[10],rx_sym1[11],rx_sym1[12],rx_sym1[13],rx_sym1[14],rx_sym1[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s  |  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s                                                                ",$time,tx_sym2[0],tx_sym2[1],tx_sym2[2],tx_sym2[3],tx_sym2[4],tx_sym2[5],tx_sym2[6],tx_sym2[7],tx_sym2[8],tx_sym2[9],tx_sym2[10],tx_sym2[11],tx_sym2[12],tx_sym2[13],tx_sym2[14],tx_sym2[15],rx_sym2[0],rx_sym2[1],rx_sym2[2],rx_sym2[3],rx_sym2[4],rx_sym2[5],rx_sym2[6],rx_sym2[7],rx_sym2[8],rx_sym2[9],rx_sym2[10],rx_sym2[11],rx_sym2[12],rx_sym2[13],rx_sym2[14],rx_sym2[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym3[0],tx_sym3[1],tx_sym3[2],tx_sym3[3],tx_sym3[4],tx_sym3[5],tx_sym3[6],tx_sym3[7],tx_sym3[8],tx_sym3[9],tx_sym3[10],tx_sym3[11],tx_sym3[12],tx_sym3[13],tx_sym3[14],tx_sym3[15],rx_sym3[0],rx_sym3[1],rx_sym3[2],rx_sym3[3],rx_sym3[4],rx_sym3[5],rx_sym3[6],rx_sym3[7],rx_sym3[8],rx_sym3[9],rx_sym3[10],rx_sym3[11],rx_sym3[12],rx_sym3[13],rx_sym3[14],rx_sym3[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym4[0],tx_sym4[1],tx_sym4[2],tx_sym4[3],tx_sym4[4],tx_sym4[5],tx_sym4[6],tx_sym4[7],tx_sym4[8],tx_sym4[9],tx_sym4[10],tx_sym4[11],tx_sym4[12],tx_sym4[13],tx_sym4[14],tx_sym4[15],rx_sym4[0],rx_sym4[1],rx_sym4[2],rx_sym4[3],rx_sym4[4],rx_sym4[5],rx_sym4[6],rx_sym4[7],rx_sym4[8],rx_sym4[9],rx_sym4[10],rx_sym4[11],rx_sym4[12],rx_sym4[13],rx_sym4[14],rx_sym4[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym5[0],tx_sym5[1],tx_sym5[2],tx_sym5[3],tx_sym5[4],tx_sym5[5],tx_sym5[6],tx_sym5[7],tx_sym5[8],tx_sym5[9],tx_sym5[10],tx_sym5[11],tx_sym5[12],tx_sym5[13],tx_sym5[14],tx_sym5[15],rx_sym5[0],rx_sym5[1],rx_sym5[2],rx_sym5[3],rx_sym5[4],rx_sym5[5],rx_sym5[6],rx_sym5[7],rx_sym5[8],rx_sym5[9],rx_sym5[10],rx_sym5[11],rx_sym5[12],rx_sym5[13],rx_sym5[14],rx_sym5[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym6[0],tx_sym6[1],tx_sym6[2],tx_sym6[3],tx_sym6[4],tx_sym6[5],tx_sym6[6],tx_sym6[7],tx_sym6[8],tx_sym6[9],tx_sym6[10],tx_sym6[11],tx_sym6[12],tx_sym6[13],tx_sym6[14],tx_sym6[15],rx_sym6[0],rx_sym6[1],rx_sym6[2],rx_sym6[3],rx_sym6[4],rx_sym6[5],rx_sym6[6],rx_sym6[7],rx_sym6[8],rx_sym6[9],rx_sym6[10],rx_sym6[11],rx_sym6[12],rx_sym6[13],rx_sym6[14],rx_sym6[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym7[0],tx_sym7[1],tx_sym7[2],tx_sym7[3],tx_sym7[4],tx_sym7[5],tx_sym7[6],tx_sym7[7],tx_sym7[8],tx_sym7[9],tx_sym7[10],tx_sym7[11],tx_sym7[12],tx_sym7[13],tx_sym7[14],tx_sym7[15],rx_sym7[0],rx_sym7[1],rx_sym7[2],rx_sym7[3],rx_sym7[4],rx_sym7[5],rx_sym7[6],rx_sym7[7],rx_sym7[8],rx_sym7[9],rx_sym7[10],rx_sym7[11],rx_sym7[12],rx_sym7[13],rx_sym7[14],rx_sym7[15]));

              forever begin
		repeat(3)      
		@(posedge clk);
		  @(posedge clk);
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s  |  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s                                                                 ",$time,tx_sym0[0],tx_sym0[1],tx_sym0[2],tx_sym0[3],tx_sym0[4],tx_sym0[5],tx_sym0[6],tx_sym0[7],tx_sym0[8],tx_sym0[9],tx_sym0[10],tx_sym0[11],tx_sym0[12],tx_sym0[13],tx_sym0[14],tx_sym0[15],rx_sym0[0],rx_sym0[1],rx_sym0[2],rx_sym0[3],rx_sym0[4],rx_sym0[5],rx_sym0[6],rx_sym0[7],rx_sym0[8],rx_sym0[9],rx_sym0[10],rx_sym0[11],rx_sym0[12],rx_sym0[13],rx_sym0[14],rx_sym0[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s  |  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s                                                                ",$time,tx_sym1[0],tx_sym1[1],tx_sym1[2],tx_sym1[3],tx_sym1[4],tx_sym1[5],tx_sym1[6],tx_sym1[7],tx_sym1[8],tx_sym1[9],tx_sym1[10],tx_sym1[11],tx_sym1[12],tx_sym1[13],tx_sym1[14],tx_sym1[15],rx_sym1[0],rx_sym1[1],rx_sym1[2],rx_sym1[3],rx_sym1[4],rx_sym1[5],rx_sym1[6],rx_sym1[7],rx_sym1[8],rx_sym1[9],rx_sym1[10],rx_sym1[11],rx_sym1[12],rx_sym1[13],rx_sym1[14],rx_sym1[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s  |  %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s %0s                                                                ",$time,tx_sym2[0],tx_sym2[1],tx_sym2[2],tx_sym2[3],tx_sym2[4],tx_sym2[5],tx_sym2[6],tx_sym2[7],tx_sym2[8],tx_sym2[9],tx_sym2[10],tx_sym2[11],tx_sym2[12],tx_sym2[13],tx_sym2[14],tx_sym2[15],rx_sym2[0],rx_sym2[1],rx_sym2[2],rx_sym2[3],rx_sym2[4],rx_sym2[5],rx_sym2[6],rx_sym2[7],rx_sym2[8],rx_sym2[9],rx_sym2[10],rx_sym2[11],rx_sym2[12],rx_sym2[13],rx_sym2[14],rx_sym2[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym3[0],tx_sym3[1],tx_sym3[2],tx_sym3[3],tx_sym3[4],tx_sym3[5],tx_sym3[6],tx_sym3[7],tx_sym3[8],tx_sym3[9],tx_sym3[10],tx_sym3[11],tx_sym3[12],tx_sym3[13],tx_sym3[14],tx_sym3[15],rx_sym3[0],rx_sym3[1],rx_sym3[2],rx_sym3[3],rx_sym3[4],rx_sym3[5],rx_sym3[6],rx_sym3[7],rx_sym3[8],rx_sym3[9],rx_sym3[10],rx_sym3[11],rx_sym3[12],rx_sym3[13],rx_sym3[14],rx_sym3[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym4[0],tx_sym4[1],tx_sym4[2],tx_sym4[3],tx_sym4[4],tx_sym4[5],tx_sym4[6],tx_sym4[7],tx_sym4[8],tx_sym4[9],tx_sym4[10],tx_sym4[11],tx_sym4[12],tx_sym4[13],tx_sym4[14],tx_sym4[15],rx_sym4[0],rx_sym4[1],rx_sym4[2],rx_sym4[3],rx_sym4[4],rx_sym4[5],rx_sym4[6],rx_sym4[7],rx_sym4[8],rx_sym4[9],rx_sym4[10],rx_sym4[11],rx_sym4[12],rx_sym4[13],rx_sym4[14],rx_sym4[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym5[0],tx_sym5[1],tx_sym5[2],tx_sym5[3],tx_sym5[4],tx_sym5[5],tx_sym5[6],tx_sym5[7],tx_sym5[8],tx_sym5[9],tx_sym5[10],tx_sym5[11],tx_sym5[12],tx_sym5[13],tx_sym5[14],tx_sym5[15],rx_sym5[0],rx_sym5[1],rx_sym5[2],rx_sym5[3],rx_sym5[4],rx_sym5[5],rx_sym5[6],rx_sym5[7],rx_sym5[8],rx_sym5[9],rx_sym5[10],rx_sym5[11],rx_sym5[12],rx_sym5[13],rx_sym5[14],rx_sym5[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym6[0],tx_sym6[1],tx_sym6[2],tx_sym6[3],tx_sym6[4],tx_sym6[5],tx_sym6[6],tx_sym6[7],tx_sym6[8],tx_sym6[9],tx_sym6[10],tx_sym6[11],tx_sym6[12],tx_sym6[13],tx_sym6[14],tx_sym6[15],rx_sym6[0],rx_sym6[1],rx_sym6[2],rx_sym6[3],rx_sym6[4],rx_sym6[5],rx_sym6[6],rx_sym6[7],rx_sym6[8],rx_sym6[9],rx_sym6[10],rx_sym6[11],rx_sym6[12],rx_sym6[13],rx_sym6[14],rx_sym6[15]));
		  $fdisplay(tracker_pl,$sformatf("%0tns  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s   |  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s  %0s                                                                 ",$time,tx_sym7[0],tx_sym7[1],tx_sym7[2],tx_sym7[3],tx_sym7[4],tx_sym7[5],tx_sym7[6],tx_sym7[7],tx_sym7[8],tx_sym7[9],tx_sym7[10],tx_sym7[11],tx_sym7[12],tx_sym7[13],tx_sym7[14],tx_sym7[15],rx_sym7[0],rx_sym7[1],rx_sym7[2],rx_sym7[3],rx_sym7[4],rx_sym7[5],rx_sym7[6],rx_sym7[7],rx_sym7[8],rx_sym7[9],rx_sym7[10],rx_sym7[11],rx_sym7[12],rx_sym7[13],rx_sym7[14],rx_sym7[15]));
	       //end
              end
            end//Tracker thread 1 end

           begin
	     forever begin
	       @(posedge clk);	     
	       if(pipe_tx_data[0]==16'h4a4a) begin
	         repeat(3)
	           @(posedge clk);	       
	         $fdisplay(tracker_pl,"%0tns                                                                                                                                                                                 >TS1(%0d)",$time,ts1_sent_cnt);
               end	       
	       if(pipe_tx_data[0]==16'h4545) begin
	         repeat(3)
	           @(posedge clk);	       
	         $fdisplay(tracker_pl,"%0tns                                                                                                                                                                                 >TS2(%0d)",$time,ts2_sent_cnt);	           end
            end 
           end
           begin
	     forever begin
	       @(posedge clk);	     
	       if(pipe_rx_data[0]==16'h4a4a)
	       $fdisplay(tracker_pl,"%0tns                                                                                                                                                                                 <TS1(%0d)",$time,ts1_rcvd_cnt);	
	       if(pipe_rx_data[0]==16'h4545)
	       $fdisplay(tracker_pl,"%0tns                                                                                                                                                                                 <TS2(%0d)",$time,ts2_rcvd_cnt);	
	    end 
           end

          begin
            //@(posedge clk);		  
	        //$fdisplay(tracker_pl,"                                                                                                                                                                               ltssm in DETECT");	           
            forever begin
              @(posedge clk);
	      if(flag_detect==1) 
	        $fdisplay(tracker_pl,"%0tns                                                                                                                                                                               ltssm in POLLING_ACTIVE",$time);	           
	      if(flag_pol_active_send && flag_pol_active_receive) begin 
		@(posedge clk);      
	        $fdisplay(tracker_pl,"%0tns                                                                                                                                                                               ltssm in POLLING_CONFIG",$time);	           
	      end	
	      if(flag_pol_config_send && flag_pol_config_receive) begin
		@(posedge clk);      
	        $fdisplay(tracker_pl,"%0tns                                                                                                                                                                               ltssm in CONFIGURATION",$time);
              end		
	      
	      if(c_to_tb==199) begin 
	        $fdisplay(tracker_pl,"%0tns                                                                                                                                                                               timer expired direct to detect state",$time);	           
	        $fdisplay(tracker_pl,"%0tns                                                                                                                                                                               ltssm in DETECT",$time);	           
             end
	   end
	  end

          /*begin
            forever begin
              @(posedge clk);
	      if(pipe_tx_data[0]==16'h4a4a || pipe_tx_data[0]==16'h4545)
	       ++send_cnt;
	      if(pipe_rx_data[0]==16'h4a4a || pipe_rx_data[0]==16'h4545)
	       ++rcv_cnt;
              /*if(!($unchanged(state_ascii_tb)))begin
                send_cnt=0;
		rcv_cnt=0;
	      end
	    end
	  end*/
            
    
	    begin
              forever begin
                @(posedge clk);
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_tx_data[i]==16'h4a4a)begin
                      tx_sym6[i]="4a";
		      tx_sym7[i]="4a";
		  end
		 end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_tx_data[i]==16'hf7bc) begin
                      tx_sym0[i]="COM";
		      tx_sym1[i]="PAD";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_tx_data[i]==16'h4ef7) begin
                      tx_sym2[i]="PAD";
		      tx_sym3[i]="4e";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_tx_data[i]==16'h307e) begin
                      tx_sym4[i]="7e";
		      tx_sym5[i]="30";
		  end
		end
              end
	    end
	    
    
            begin
              forever begin
                @(posedge clk);
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_rx_data[i]==16'h4a4a)begin
                      rx_sym6[i]="4a";
		      rx_sym7[i]="4a";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_rx_data[i]==16'hf7bc) begin
                      rx_sym0[i]="COM";
		      rx_sym1[i]="PAD";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_rx_data[i]==16'h4ef7) begin
                      rx_sym2[i]="PAD";
		      rx_sym3[i]="4e";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_rx_data[i]==16'h307e) begin
                      rx_sym4[i]="7e";
		      rx_sym5[i]="30";
		  end
		end
              end
	    end

           begin
             forever begin
               @(posedge clk);
	       for(int i=0;i<=15;i++) begin		
		    if(pipe_rx_data[i]==16'h0 && state_ascii_tb=="CONFIGURATION") begin
                      rx_sym0[i]="";
		      rx_sym1[i]="";
                      rx_sym2[i]="";
                      rx_sym3[i]="";
                      rx_sym4[i]="";
		      rx_sym5[i]="";
		      rx_sym6[i]="";
		      rx_sym7[i]="";
		  end
	     end
	   end
          end
    
            begin
              forever begin
                @(posedge clk);
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_tx_data[i]==16'h4545)begin
                      tx_sym6[i]="45";
		      tx_sym7[i]="45";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_tx_data[i]==16'hf7bc) begin
                      tx_sym0[i]="COM";
		      tx_sym1[i]="PAD";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_tx_data[i]==16'h4ef7) begin
                      tx_sym2[i]="PAD";
		      tx_sym3[i]="4e";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_tx_data[i]==16'h327e) begin
                      tx_sym4[i]="7e";
		      tx_sym5[i]="32";
		  end
		end
              end
	    end
	    
    
            begin
              forever begin
                @(posedge clk);
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_rx_data[i]==16'h4545)begin
                      rx_sym6[i]="45";
		      rx_sym7[i]="45";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_rx_data[i]==16'hf7bc) begin
                      rx_sym0[i]="COM";
		      rx_sym1[i]="PAD";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_rx_data[i]==16'h4ef7) begin
                      rx_sym2[i]="PAD";
		      rx_sym3[i]="4e";
		  end
		end
	          for(int i=0;i<=15;i++) begin		
		    if(pipe_rx_data[i]==16'h327e) begin
                      rx_sym4[i]="7e";
		      rx_sym5[i]="32";
		  end
		end
              end
	    end

          join_any
          l++;
          $display("ITERATION :%0d completed at time :%0tns",l,$time);
          disable fork;
        end
      end

      begin
        #100000;
        $display("Completed overall timeout at time:%0tns",$time);
      end
    join_any 
      
 $finish;

  end

  endmodule
