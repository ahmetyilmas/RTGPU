`timescale 1ns / 1ps
`include "Types.sv"
/*
    16 WIDTH, 12 Q_BITS ve 20 DEPTH icin sentez sonuclari
    LUT:    5012
    FF:     3881
    BRAM:   1.50
    LUTRAM: 80
*/
    // len = sqrt(x^2 + y^2 + z^2)
    // L'x = Lx / len
    // L'y = Ly / len
    // L'z = Lz / len
module pipelined_normalization #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter MAX = `MAX_16,
    parameter MIN = `MIN_16
    )(
    input clk,
    input reset,
    input start,
    input RayDirection ray_in,
    output RayDirection normalized_ray_out, // normalized x,y,z directions
    output logic valid_out
    );

    logic mul_valid;

    // isin yonlerinin kareleri
    RayDirection_sqr RD_square;

    direction_square #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) dir_sqr (
    .clk(clk),
    .start(start),
    .RD_in(ray_in),
    .valid_out(mul_valid),
    .RDS_out(RD_square)
    );

    wire [WIDTH-1:0]sum;
    RayDirection RD_sqrt_in;

    assign sum = RD_square.sqr_x + RD_square.sqr_y + RD_square.sqr_z;
    assign RD_sqrt_in = '{
        x : RD_square.x,
        y : RD_square.y,
        z : RD_square.z
    };

    logic sqrt_valid;
    RayDirection_len RD_len;

    direction_sqroot #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS),
    .DEPTH(20)
    ) sqrt_core (
    .clk(clk),
    .start(mul_valid),
    .reset(reset),
    .sum_in(sum),
    .RD_in(RD_sqrt_in),
    .valid_out(sqrt_valid),
    .RDLEN_out(RD_len),
    .overflow_out()
    );

    NR_div_block #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MAX(MAX),
        .MIN(MIN)
    ) NR_division (
        .clk(clk),
        .reset(reset),
        .start(sqrt_valid),
        .RDL_in(RD_len),
        .valid_out(valid_out),
        .normalized_ray_out(normalized_ray_out)
    );

endmodule
