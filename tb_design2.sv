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
 bit flag_detect,flag_pol_active_send,flag_pol_active_receive,flag_pol_config_send,flag_pol_config_receive;
 int fd_3;
 int l;

 ltssm_x DUT(.clk(clk),
           .reset(reset),
	   .pipe_tx_data(pipe_rx_data),
           .pipe_rx_data(pipe_tx_data)
           );
always #5 clk=~clk;

  task send_ts1;
    //@(negedge clk);
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
    //@(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h4545;
    end
    @(negedge clk);
     for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'hf7bc;
    end
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h4ec7;
    end
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h327e;
    end
  endtask

  initial begin
    fd_3=$fopen("state_trans.txt","w");	  
    reset=1;
    @(negedge clk);
    reset=0;
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
                end
             end
            end
          end//Timeout thread for states in tb begin	      

          begin//outer thread-0 begin
            @(negedge clk);
            forever begin
              if(state_ascii_tb=="DETECT" || state_ascii_tb=="POL_ACTIVE") begin
                ts1_send_cnt[0]++;
                send_ts1();
              end
              else if(state_ascii_tb=="POL_CONFIG") begin
                ts2_send_cnt[0]++;
                send_ts2();
              end
              else if(state_ascii_tb=="CONFIGURATION") begin
                send_ts1();
              end
            end
            $display("Thread-0 completed at time:%0t",$time);
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
            $display("Thread-1 completed at time:%0t",$time);
          end//outer thread-1 end

          begin//outer thread-2 begin
            forever begin
              @(negedge clk);
              wait(state_ascii_tb=="POL_ACTIVE");
              if(pipe_rx_data[0]==16'h4a4a) begin
                ts1_rcv_cnt[0]++;
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
              if(pipe_rx_data[0]==16'h4545) begin
                ts2_rcv_cnt[0]++;
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
            $display("Thread-2 completed at time:%0t",$time);
          end//outer thread-2 end

          
          begin//outer thread-3 begin
            forever begin
              @(negedge clk);
              if(flag_detect==1) begin
                $fdisplay(fd_3,$sformatf("Enetered the flag_detect state at : %0t",$time));
                state_ascii_tb = "POL_ACTIVE";
                flag_detect=0;
              end
              else if(flag_pol_active_send && flag_pol_active_receive) begin
                $fdisplay(fd_3,$sformatf("Enetered the flag_pol_active state at : %0t",$time));
                @(negedge clk);		  
                state_ascii_tb="POL_CONFIG";
                flag_pol_active_send=0;
                flag_pol_active_receive=0;
              end
              else if(flag_pol_config_send && flag_pol_config_receive) begin
                $fdisplay(fd_3,$sformatf("Enetered the configuration state at : %0t",$time));
                @(negedge clk);
                state_ascii_tb="CONFIGURATION";
                flag_pol_config_send=0;
                flag_pol_config_receive=0;
                repeat(210)
                  @(negedge clk);
                  ->ev;
              end 

            end
            $display("Thread-3 completed at time:%0t",$time);
          end//outer thread-3 end


        join_any
        l++;
        $display("ITERATION :%0d completed at time :%0t",l,$time);
        disable fork;
      end
    end

    begin
      #50000;
      $display("Completed overall timeout at time:%0t",$time);
    end
 join_any 
      
 $finish;

  end

  endmodule
