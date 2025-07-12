`timescale 1ns / 1ps
`include "Types.sv"

/*
    TaggedDirection struct'u icin dual port, BRAM FIFO
    48 TAG_SIZE, 16 WIDTH, 32 DEPTH icin kullanimlar (192 byte)
    LUT  = 20
    FF   = 19
    BRAM = 2.50
*/
module td_dp_fifo #(
    parameter WIDTH = `WIDTH,
    parameter TAG_SIZE = `TAG_SIZE,
    parameter DEPTH = 32
    )(
    input clk,
    input reset,
    input read,
    input write,
    input TaggedDirection dir_in,
    output TaggedDirection dir_out,
    output logic ready,
    output logic overflow,
    output logic valid_out
    );
    
    wire [WIDTH-1:0]    dir_x;
    wire [WIDTH-1:0]    dir_y;
    wire [WIDTH-1:0]    dir_z;
    wire [TAG_SIZE-1:0] tag;
    
    assign dir_x = dir_in.direction.x;
    assign dir_y = dir_in.direction.y;
    assign dir_z = dir_in.direction.z;
    assign tag   = dir_in.tag;
    
    logic [WIDTH-1:0]    out_x;
    logic [WIDTH-1:0]    out_y;
    logic [WIDTH-1:0]    out_z;
    logic [TAG_SIZE-1:0] out_tag;
    logic valid;
    
    (*ram_style = "block" *) logic [WIDTH-1:0] fifo_x [0:DEPTH-1];
    (*ram_style = "block" *) logic [WIDTH-1:0] fifo_y [0:DEPTH-1];
    (*ram_style = "block" *) logic [WIDTH-1:0] fifo_z [0:DEPTH-1];
    (*ram_style = "block" *) logic [TAG_SIZE-1:0] fifo_tag [0:DEPTH-1];
    
    logic [$clog2(DEPTH)-1:0] wptr, rptr;
    logic [$clog2(DEPTH+1)-1:0] fifo_count;
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            wptr <= 0;
            rptr <= 0;
            fifo_count <= 0;
            overflow <= 0;
            valid <= 0;
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
        overflow <= (fifo_count == DEPTH);
    end
    
    always_ff @(posedge clk) begin
        if(write) begin
            fifo_x[wptr]   <=  dir_x;
            fifo_y[wptr]   <=  dir_y;
            fifo_z[wptr]   <=  dir_z;
            fifo_tag[wptr] <= tag;
        end
        if(read) begin
            out_x   <= fifo_x[rptr];
            out_y   <= fifo_y[rptr];
            out_z   <= fifo_z[rptr];
            out_tag <= fifo_tag[rptr];
        end
    end
    
    assign ready = fifo_count > 0;
    assign valid_out = valid;
    assign dir_out = '{
                        direction : '{
                            x : '{out_x},
                            y : '{out_y},
                            z : '{out_z}
                            },
                        tag : '{out_tag}};
endmodule
