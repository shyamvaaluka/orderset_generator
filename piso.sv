`timescale 1ns/1ps

module piso (
    input  logic        clk,
    input  logic        rst,

    // parallel inputs (one block per load)
    input  logic        load,
    input  logic [15:0] i0,
    input  logic [15:0] i1,
    input  logic [15:0] i2,
    input  logic [15:0] i3,
    input  logic [2:0]ltssm_states_h,

    // serial output
    output logic [15:0] out,

    // status signals (optional but useful)
    output logic        fifo_full,
    output logic        fifo_empty,
    output logic [31:0]cnt,
    output logic [31:0]ts1_count,ts2_count
);

    //--------------------------------------------
    // FIFO parameters
    //--------------------------------------------

    localparam FIFO_DEPTH = 16;
    localparam FIFO_WIDTH = 64;
    localparam PTR_WIDTH  = 4;   // log2(4) = 2
    int ts_cnt,ts1_cnt,ts2_cnt;

    //--------------------------------------------
    // FIFO storage
    //--------------------------------------------

    logic [FIFO_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    logic [PTR_WIDTH:0]   fifo_count;

    //--------------------------------------------
    // FIFO write logic (parallel block write)
    //--------------------------------------------

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end
        else if (load && !fifo_full) begin
            fifo_mem[wr_ptr] <= {i0,i1,i2,i3};
            wr_ptr <= wr_ptr + 1;
        end
    end

    //--------------------------------------------
    // FIFO read logic control
    //--------------------------------------------

    logic [63:0] piso_reg;
    logic [1:0]  shift_count;
    logic        piso_busy;

    always_ff @(posedge clk) begin
        if (rst) begin
            rd_ptr      <= 0;
            piso_busy   <= 0;
            shift_count <= 0;
            piso_reg    <= 0;
        end
        else begin

            // Load new block into PISO when idle
            if (!piso_busy && !fifo_empty) begin
                piso_reg    <= fifo_mem[rd_ptr];
                rd_ptr      <= rd_ptr + 1;
                piso_busy   <= 1;
                shift_count <= 0;
            end

            // Shift operation
            else if (piso_busy) begin
                piso_reg <= {piso_reg[47:0],16'd0};

                if (shift_count == 2'd3) begin
                    piso_busy <= 0;
		    ts_cnt++;
                end
                else begin
                    shift_count <= shift_count + 1;
                end
            end

        end
    end

    //--------------------------------------------
    // Output assignment
    //--------------------------------------------

    assign out = piso_reg[63:48];
    assign cnt = ts_cnt;
    assign ts1_count = ts1_cnt;
    assign ts2_count = ts2_cnt;

    //--------------------------------------------
    // FIFO count logic
    //--------------------------------------------

    always_ff @(posedge clk) begin
        if (rst) begin
            fifo_count <= 0;
        end
        else begin
            case ({load && !fifo_full, (!piso_busy && !fifo_empty)})
                2'b10: fifo_count <= fifo_count + 1;
                2'b01: fifo_count <= fifo_count - 1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end


    /*always@(*) begin
      if(ltssm_states_h==0)begin
        ts1_cnt=0;
        ts2_cnt=0;
      end
      else if(piso_reg[63:48]==16'h4a4a || ltssm_states_h==1)begin
        ts1_cnt=0;
        ts1_cnt++;
      end
      else if(piso_reg[63:48]==16'h4545 || ltssm_states_h==2)begin
        ts2_cnt=0;
	ts2_cnt++;
      end
      else if(ltssm_states_h==3)begin
        ts2_cnt=0;
	ts1_cnt=0;
      end
      
    end*/

//logic [31:0] ts1_cnt, ts2_cnt;

always_ff @(posedge clk) begin
    if (rst) begin
        ts1_cnt <= 0;
        ts2_cnt <= 0;
    end
    else begin
        case (ltssm_states_h)
            0: begin
                ts1_cnt <= 0;
                ts2_cnt <= 0;
            end

            1: begin
	        ts1_cnt <=0;
		ts2_cnt <=0;
                if (piso_reg[63:48]==16'h4a4a)
                    ts1_cnt <= ts1_cnt + 1;
                else
                    ts1_cnt <= ts1_cnt;  // hold
                ts2_cnt <= ts2_cnt;      // hold
            end

            2: begin
	        ts1_cnt <=0;
		ts2_cnt <=0;
                if (piso_reg[63:48]==16'h4545)
                    ts2_cnt <= ts2_cnt + 1;
                else
                    ts2_cnt <= ts2_cnt;   // hold
                ts1_cnt <= ts1_cnt;       // hold
            end

            3: begin
                ts1_cnt <= 0;
                ts2_cnt <= 0;
            end

            default: begin
                ts1_cnt <= ts1_cnt;
                ts2_cnt <= ts2_cnt;
            end
        endcase
    end
end
    

    //--------------------------------------------
    // FIFO status signals
    //--------------------------------------------

    assign fifo_full  = (fifo_count == FIFO_DEPTH);
    assign fifo_empty = (fifo_count == 0);

endmodule


