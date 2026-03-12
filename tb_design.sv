`timescale 1ns/1ps
module ltssm_top;
 
 reg clk=0;
 reg reset;
 reg[15:0]pipe_rx_data[0:15];
 logic[15:0]pipe_tx_data[0:15];

 bit[15:0]ts1_send_cnt[0:15];
 bit[15:0]ts2_send_cnt[0:15];
 bit[15:0]ts1_rcv_cnt[0:15];
 bit[15:0]ts2_rcv_cnt[0:15];
 bit[8*20:1]state_ascii_tb;
 int flag,pol_active,fd,i,ts_flag;
 int pol_config,configure;

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
     pipe_tx_data[i]=16'h4ec7;
    end
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
     pipe_tx_data[i]=16'h327e;
    end
  endtask

  initial  begin
    fd=$fopen("check.txt","w");
    state_ascii_tb="Detect";
    reset=1;
    @(negedge clk);
    reset=0;
    #5;
    fork
      begin
        repeat(5) begin
	  send_ts1();
	 for(int i=0;i<=15;i++)
	   ts1_send_cnt[i]++;
         
	end
	for(int i=0; i<=15; i++)begin
	  if(ts1_send_cnt[i] == 5)
	    ts1_send_cnt[i]=0;
        end
	pol_active=1;
	$fdisplay(fd,"------Thread 1 pol_active is %0d %0t------",pol_active,$time);
	fork
	  begin
	    forever begin
	      send_ts1();
	     for(int i=0;i<=15;i++)
	       ts1_send_cnt[i]++;
	    end
	  end
	  begin
	    wait(pol_config ==1);
	  end
	join_any
	disable fork;
	#500;
        fork
	  begin
	    forever begin
              send_ts2();
              for(int i=0;i<=15;i++)
	       ts2_send_cnt[i]++;
	    end
	  end
	  begin
	    wait(configure==1);
	  end
	 join_any
	 disable fork;
	#500;
      end

      begin
        while(1) begin
	  i++;
	  $fdisplay(fd,"========check%0d==========%0t",i,$time);
          @(posedge clk);
          for(int i=0; i<=15; i++)begin
           if(pipe_rx_data[i] == 16'h4a4a)
	    ts1_rcv_cnt[i]++; 
	    $fdisplay(fd,"rcv_cnt%0d %0t",i,$time);
	  end
	  if(pol_active == 1)begin
	    $fdisplay(fd,"------pol_active is %0d------%0t",pol_active,$time);
	    for(int i=0;i<=15;i++)
	      ts1_rcv_cnt[i]=0;
	      flag=1;
	      $display("flag=%0d time:%0t",flag,$time);
	  end
	  if(flag==1)
	    break;
	end
	while(1) begin
          @(posedge clk);
         for(int i=0; i<=15; i++)begin
           if(pipe_rx_data[i] == 16'h4a4a)
	    ts1_rcv_cnt[i]++; 
	  end
	  if(ts1_rcv_cnt[0]==12)
	   pol_config=1;

	  if(pol_config == 1)
	    break;
	end
	while(1) begin
          @(posedge clk);
          for(int i=0; i<=15; i++)begin
           if(pipe_rx_data[i] == 16'h4545)
	    ts2_rcv_cnt[i]++; 
	  end
	  if(ts2_rcv_cnt[0]==16)
	   configure=1;

	 if(configure == 1)
	  break;
	end
	#5000;
        $display("Thread1 completed");
      end

     begin
       #500000;
     end
    join_any
    $finish;
  end

  	   
endmodule
