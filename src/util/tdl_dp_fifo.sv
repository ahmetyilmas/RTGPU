`timescale 1ns / 1ps
`include "Types.sv"

/*
    TaggedDirection_len strcut'u icin dual port BRAM FIFO
    48 bit tag_size, 16 WIDTH, 32 DEPTH icin kullanimlar
    LUT  = 20
    FF   = 18
    BRAM = 3.0
*/
module tdl_dp_fifo#(
    parameter WIDTH = `WIDTH,
    parameter DEPTH = 32,
    parameter TAG_SIZE = `TAG_SIZE
    )(
    input clk,
    input reset,
    input read,
    input write,
    input TaggedDirection_len TDL_in,
    output TaggedDirection_len TDL_out,
    output logic ready,
    output logic overflow,
    output logic valid_out
    );
    
    wire [WIDTH-1:0]    dir_x;
    wire [WIDTH-1:0]    dir_y;
    wire [WIDTH-1:0]    dir_z;
    wire [TAG_SIZE-1:0] tag;
    wire [WIDTH-1:0]    len;
    
    assign dir_x = TDL_in.direction.x;
    assign dir_y = TDL_in.direction.y;
    assign dir_z = TDL_in.direction.z;
    assign tag   = TDL_in.tag;
    assign len   = TDL_in.len;
    
    logic [WIDTH-1:0]    out_x;
    logic [WIDTH-1:0]    out_y;
    logic [WIDTH-1:0]    out_z;
    logic [TAG_SIZE-1:0] out_tag;
    logic [WIDTH-1:0]    out_len;
    logic valid;

    (*ram_style = "block" *) logic [WIDTH-1:0] fifo_x [0:DEPTH-1];
    (*ram_style = "block" *) logic [WIDTH-1:0] fifo_y [0:DEPTH-1];
    (*ram_style = "block" *) logic [WIDTH-1:0] fifo_z [0:DEPTH-1];
    (*ram_style = "block" *) logic [TAG_SIZE-1:0] fifo_tag [0:DEPTH-1];
    (*ram_style = "block" *) logic [WIDTH-1:0] fifo_len [0:DEPTH-1];

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
            fifo_x[wptr]   <=  dir_x;
            fifo_y[wptr]   <=  dir_y;
            fifo_z[wptr]   <=  dir_z;
            fifo_tag[wptr] <=  tag;
            fifo_len[wptr] <=  len;
        end
        if(read) begin
            out_x   <= fifo_x[rptr];
            out_y   <= fifo_y[rptr];
            out_z   <= fifo_z[rptr];
            out_tag <= fifo_tag[rptr];
            out_len <= fifo_len[rptr];
        end
    end
    
    assign ready = fifo_count > 0;
    assign valid_out = valid;
    assign TDL_out = '{
            direction : '{
                x : '{out_x},
                y : '{out_y},
                z : '{out_z}
                },
            tag : '{out_tag},
            len : '{out_len}};
endmodule
