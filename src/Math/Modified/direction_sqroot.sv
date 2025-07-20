`timescale 1ns/1ps
`include "Types.sv"
/*
    16 WIDTH, 20 DEPTH icin sentez sonuclari
    LUT: 50,
    FF:  50,
    BRAM: 1.50
*/
module direction_sqroot #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter DEPTH = 20
) (
    input clk,
    input reset,
    input start,
    input RayDirection RD_in,
    input logic [WIDTH-1:0] sum_in,
    
    output RayDirection_len RDLEN_out,
    output valid_out,
    output overflow_out
);

    logic sqrt_valid;
    logic fifo_overflow;
    logic fifo_valid;
    logic valid;

    logic [WIDTH+Q_BITS-1:0]sum_in_ext;
    assign sum_in_ext = {sum_in,{Q_BITS{1'b0}}};

    logic signed [WIDTH-1:0]len;
    
    RayDirection RD_ff;
    RayDirection_len RDLEN_ff;

    RD_fifo #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
    ) RD_buffer (
    .clk(clk),
    .reset(reset),
    .read_in(sqrt_valid),
    .write_in(start),
    .RD_in(RD_in),
    .RD_out(RD_ff),
    .ready_out(),
    .overflow_out(fifo_overflow),
    .valid_out(fifo_valid)
    );

    cordic_0 sqrt_core (
        .aclk(clk),
        .s_axis_cartesian_tdata(sum_in_ext),
        .s_axis_cartesian_tvalid(start),
        .m_axis_dout_tdata(len),
        .m_axis_dout_tvalid(sqrt_valid)
    );
    
    logic signed [WIDTH-1:0]len_ff;
    
    always_ff @( posedge clk) begin
        if(reset) begin
            len_ff <= 0;
        end else if(sqrt_valid) begin
            len_ff <= len;
        end else begin
            len_ff <= 0;
        end
    end 
    
    always_ff @(posedge clk) begin
        if(reset) begin
            RDLEN_ff <= 0;
            valid <= 0;
        end else begin
            if(fifo_valid) begin
                RDLEN_ff <= '{
                x: RD_ff.x,
                y: RD_ff.y,
                z: RD_ff.z,

                len : len_ff};

                valid <= 1;
            end else begin
                valid <= 0;
            end
        end
    end
    assign RDLEN_out = RDLEN_ff;
    assign valid_out = valid;
    assign overflow_out = fifo_overflow;
endmodule