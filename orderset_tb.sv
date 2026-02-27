module orderset_top;

  reg clk=0;
  reg rst;
  reg[31:0]command;
  reg[2:0]ltssm_states_h[0:15];
  wire[15:0]pipe_tx_data[0:15];
  wire[31:0]cnt[0:15];
  wire[31:0]ts1_cnt[0:15];
  wire[31:0]ts2_cnt[0:15];
  int fd1,fd2,l,k;
  orderset DUT(.clk(clk),.rst(rst),.command(command),.pipe_tx_data(pipe_tx_data),.cnt(cnt),.ts1_cnt(ts1_cnt),.ts2_cnt(ts2_cnt),.ltssm_states_h(ltssm_states_h));

  always #5 clk=~clk;

  task cmd(input[31:0]x);
   @(negedge clk);
   command=x;
  endtask

  initial begin
  fd1=$fopen("./ts1_done.txt","w+");
  fd2=$fopen("./ts2_done.txt","w+");
    rst=1;
    for(int i=0;i<=15;i++)begin
    ltssm_states_h[i]=0;
    end
    @(negedge clk);
    rst=0;
    /*cmd(1);
    #10;
    cmd(0);
    #5;
    cmd(1);*/
    
    @(negedge clk);
    for(int i=0;i<=15;i++)begin
    ltssm_states_h[i]=1;
    end
    command=0;
    fork
      begin
      while(1)begin
        @(posedge clk);
	  $fdisplay(fd1,"============count_ts1%0d==============",l++);
        for(int j=0;j<=15;j++)begin
          if(ts1_cnt[j] == 12)begin
	   $fdisplay(fd1,$sformatf("ts1 count done at time=%0t",$time));
           @(negedge clk);
           for(int i=0;i<=15;i++)begin
            ltssm_states_h[i]=2;
           end
           command=1;
           break;
          end
        end
      end
      while(1) begin
        @(posedge clk);
	  $fdisplay(fd2,"============count_ts2%0d==============",k++);
        for(int j=0;j<=15;j++)begin
          if(ts2_cnt[j] == 12)begin
	   $fdisplay(fd2,$sformatf("ts2 count done at time=%0t",$time));
           @(negedge clk);
           for(int i=0;i<=15;i++)begin
            ltssm_states_h[i]=3;
           end
            #300;
            break;
          end
        end
      end
      end


      begin
      #10000000;
      end
    join_any
    $finish;
  end 

endmodule
