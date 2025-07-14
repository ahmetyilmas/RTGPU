`timescale 1ns / 1ps
`include "Types.sv"

module fifo#(
    parameter WIDTH = `WIDTH,
    parameter DEPTH = 32
    )(
    input clk,
    input reset,
    input read,
    input write,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output logic ready,
    output logic overflow,
    output logic valid_out
    );
    
    
    (*ram_style = "block" *) logic [WIDTH-1:0] fifo [0:DEPTH-1];

    logic valid;
    logic [WIDTH-1:0] out;
    
    logic [$clog2(DEPTH)-1:0] wptr;
    logic [$clog2(DEPTH)-1:0] rptr;
    logic [$clog2(DEPTH+1)-1:0] fifo_count;
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            wptr <= 0;
            rptr <= 0;
            fifo_count <= 0;
            overflow <= 0;
            valid <= 0;
        end else begin
            if(write && read && fifo_count > 0 && fifo_count < DEPTH) begin
                    wptr <= (wptr + 1) % DEPTH;
                    rptr <= (rptr + 1) % DEPTH;
                    valid <= 1;
            end else begin
                if(write && fifo_count < DEPTH) begin
                   wptr <= (wptr + 1) % DEPTH;
                   fifo_count <= fifo_count + 1;
                end
                
                if(read && fifo_count > 0) begin
                    rptr    <= (rptr + 1 ) % DEPTH;
                    fifo_count <= fifo_count - 1;
                    valid   <= 1;
                    overflow <= 0;
                end
            end
        end
        overflow <= (fifo_count == DEPTH);
    end

    always_ff @(posedge clk) begin
        if(write) begin
            fifo[wptr]   <=  data_in;
        end
        if(read) begin
            out   <= fifo[rptr];
        end
    end
    
    assign ready = (fifo_count > 0);
    assign data_out = out;
    assign valid_out = valid;
endmodule
