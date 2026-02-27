`include "piso.sv"
`timescale 1ns/1ps

module orderset(input clk,
                input rst,
		input[2:0]ltssm_states_h[0:15],
	        input[31:0]command,
		output reg[15:0]pipe_tx_data[0:15],
		output reg[31:0]cnt[0:15],
		output reg[31:0]ts1_cnt[0:15],
		output reg[31:0]ts2_cnt[0:15]);

  localparam TS1=0;
  localparam TS2=1;
  localparam IDLE=2;

   
  

  reg[15:0]temp1[0:15];
  reg[15:0]temp2[0:15];
  reg[15:0]temp3[0:15];
  reg[15:0]temp4[0:15];

  reg[8*20:1]os_state_ascii;

  reg[1:0]state, next_state;
  reg load[0:15];
  reg ready[0:15];
  reg n_ready[0:15];

  genvar i;

  generate
    for(i=0;i<=15;i++)begin
      piso DUT(.i0(temp1[i]),
               .i1(temp2[i]),
               .i2(temp3[i]),
               .i3(temp4[i]),
               .out(pipe_tx_data[i]), 
               .load(load[i]),
	       .clk(clk),
	       .rst(rst),
               .fifo_full(n_ready[i]),
	       .fifo_empty(ready[i]),
	       .cnt(cnt[i]),
	       .ts1_count(ts1_cnt[i]),
	       .ts2_count(ts2_cnt[i]),
	       .ltssm_states_h(ltssm_states_h[i])
                ); 

    end

  endgenerate

  //reg[31:0]ts1_rcvd_cnt,ts1_sent_cnt,ts2_rcvd_cnt,ts2_sent_cnt;

  always_ff@(posedge clk) begin 
     if(rst) begin
       state<=IDLE;
     end
     else begin
       state<=next_state;
     end
  end

  always@(*)begin
    case(state)
      TS1: begin
           if(command == 0)begin
             next_state=TS1;
	   end
	   else if(command == 1)
	     next_state=TS2;
	   else if(command == 2)
	     next_state=IDLE;
	   os_state_ascii="TS1";
      end

      TS2: begin
           if(command == 1)begin
             next_state=TS2;
	   end
	   else if(command == 0)
	     next_state=TS1;
	   else if(command == 2)
	     next_state=IDLE;
	   os_state_ascii="TS2";
      end

      IDLE: begin
           if(command == 2)begin
             next_state=IDLE;
	   end
	   else if(command == 1)
	     next_state=TS2;
	   else if(command==0)
	     next_state=TS1;
	   os_state_ascii="IDLE";
      end

      default: begin
          next_state=IDLE; 
	  os_state_ascii="IDLE";
      end


    endcase
  end


  always@(*)begin
    case(state)
      TS1: begin
           for(int i=0;i<=15;i++)begin
                temp1[i]=16'h4a4a;
                temp2[i]=16'hf7bc;
                temp3[i]=16'h4ef7;
                temp4[i]=16'h307e;
	   end
	   
      end

      TS2: begin
           for(int i=0;i<=15;i++)begin
             temp1[i]=16'h4545;
             temp2[i]=16'hf7bc;
             temp3[i]=16'h4ef7;
             temp4[i]=16'h307e;
	    
	   end
      end

      IDLE: begin
           for(int i=0;i<=15;i++)begin
                temp1[i]=16'h0;
                temp2[i]=16'h0;
                temp3[i]=16'h0;
                temp4[i]=16'h0;
	      
	      end
      end

      default: begin
           for(int i=0;i<=15;i++)begin
             temp1[i]=16'h0;
             temp2[i]=16'h0;
             temp3[i]=16'h0;
             temp4[i]=16'h0;
	   end
	   
      end 
 

    endcase
  end


  always@(*)begin
     for(int j=0;j<=15;j++)begin
       load[j] = !n_ready[j];
     end
  end
endmodule
