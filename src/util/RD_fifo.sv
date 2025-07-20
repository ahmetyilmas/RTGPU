`timescale 1ns / 1ps
`include "Types.sv"
/*
    16 WIDTH, 20 DEPTH icin sentez sonuclari
    LUT: 41,
    FF:  18,
    BRAM: 1.50
*/
module RD_fifo #(
    parameter WIDTH = `WIDTH,
    parameter DEPTH = 20
    )(
    input clk,
    input reset,
    input read_in,
    input write_in,
    input RayDirection RD_in,
    output RayDirection RD_out,
    output logic ready_out,
    output logic overflow_out,
    output logic valid_out
    );
    
    wire [WIDTH-1:0]    dir_x;
    wire [WIDTH-1:0]    dir_y;
    wire [WIDTH-1:0]    dir_z;

    logic [WIDTH-1:0]    out_x;
    logic [WIDTH-1:0]    out_y;
    logic [WIDTH-1:0]    out_z;

    logic valid;
    logic overflow;

    assign dir_x = RD_in.x;
    assign dir_y = RD_in.y;
    assign dir_z = RD_in.z;

    (*ram_style = "block"*) logic [WIDTH-1:0] fifo_x [0:DEPTH-1];
    (*ram_style = "block"*) logic [WIDTH-1:0] fifo_y [0:DEPTH-1];
    (*ram_style = "block"*) logic [WIDTH-1:0] fifo_z [0:DEPTH-1];

    logic [$clog2(DEPTH)-1:0] wptr;
    logic [$clog2(DEPTH)-1:0] rptr;
    logic [$clog2(DEPTH+1):0] fifo_count;

    always_ff @( posedge clk ) begin : pointer
        if(reset) begin
            wptr <= 0;
            rptr <= 0;
            fifo_count <= 0;
            overflow <= 0;
            valid <= 0; 
        end else begin
            if(write_in && read_in && fifo_count > 0 && fifo_count < DEPTH) begin
                wptr <= (wptr + 1) % DEPTH;
                rptr <= (rptr + 1) % DEPTH;
                valid <= 1;
            end else begin
                if(write_in && fifo_count < DEPTH) begin
                   wptr <= (wptr + 1) % DEPTH;
                   fifo_count <= fifo_count + 1;
                end
                if(read_in && fifo_count > 0) begin
                    rptr       <= (rptr + 1 ) % DEPTH;
                    fifo_count <= fifo_count - 1;
                    valid      <= 1;
                    overflow   <= 0;
                end
            end
        end
        overflow <= (fifo_count == DEPTH);
    end

    always_ff @( posedge clk ) begin : outputs
        if(write_in) begin
            fifo_x[wptr] <=  dir_x;
            fifo_y[wptr] <=  dir_y;
            fifo_z[wptr] <=  dir_z;
        end
        if(read_in) begin
            out_x <= fifo_x[rptr];
            out_y <= fifo_y[rptr];
            out_z <= fifo_z[rptr];
            end
    end

    assign ready_out = fifo_count > 0;
    assign valid_out = valid;
    assign overflow_out = overflow;
    assign RD_out = '{
        x : out_x,
        y : out_y,
        z : out_z
    };
endmodule