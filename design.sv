`include "../pratice2.sv/orderset.sv"
`timescale 1ns/1ps
module ltssm(input clk,
                   rst);
  localparam DETECT=0;
  localparam POLLING_ACTIVE=1;
  localparam POLLING_CONFIG=2;
  localparam CONFIGURATION=3;
  
  reg[31:0]d_to,pa_to,pc_to,c_to;
  reg[1:0]state, next_state;
  
  reg[8*20:1] state_ascii;

  
  
  always@(posedge clk) begin
    if(rst)
      state<=0;
    else
      state<=next_state;
  end
  
  always@(posedge clk) begin
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
        if(d_to == 100)//2ms
          next_state=POLLING_ACTIVE;
        else
          next_state=DETECT;
      end
      
      POLLING_ACTIVE: begin
        if(pa_to == 200)//24ms
           next_state=POLLING_CONFIG;
        else
           next_state=POLLING_ACTIVE;
      end
      
      
       POLLING_CONFIG: begin
         if(pc_to == 300)//48ms
           next_state= CONFIGURATION;
        else
           next_state=POLLING_CONFIG;
      end
      
       CONFIGURATION: begin
         if(c_to == 200)//24ms
           next_state= DETECT;
        else
           next_state=CONFIGURATION;
      end
      
      default: next_state=DETECT;
    endcase
  end
  
endmodule
