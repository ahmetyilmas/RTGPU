`timescale 1ns/1ps
`include "Types.sv"
/*
    16 WIDTH, 12 Q_BITS icin sentez sonuclari
    4968 LUT,
    3782 FF,
    80 LUTRAM
*/
module NR_div_block #(
    WIDTH  = `WIDTH,
    Q_BITS = `Q_BITS,
    MAX    = `MAX_16,
    MIN    = `MIN_16
)(
    input clk,
    input start,
    input reset,
    input RayDirection_len RDL_in,
    output logic valid_out,
    output RayDirection normalized_ray_out
);

    logic valid_x, valid_y, valid_z;

    wire [WIDTH-1:0]quotient_x;
    wire [WIDTH-1:0]quotient_y;
    wire [WIDTH-1:0]quotient_z;

    non_restoring_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MAX(MAX),
        .MIN(MIN)
    ) NRD_X (
        .clk(clk),
        .reset(reset),
        .start(start),
        .dividend_in(RDL_in.x),
        .divisor_in(RDL_in.len),
        .quotient_out(quotient_x),
        .valid_out(valid_x)
    );
    non_restoring_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MAX(MAX),
        .MIN(MIN)
    ) NRD_Y (
        .clk(clk),
        .reset(reset),
        .start(start),
        .dividend_in(RDL_in.y),
        .divisor_in(RDL_in.len),
        .quotient_out(quotient_y),
        .valid_out(valid_y)
    );
    non_restoring_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MAX(MAX),
        .MIN(MIN)
    ) NRD_Z (
        .clk(clk),
        .reset(reset),
        .start(start),
        .dividend_in(RDL_in.z),
        .divisor_in(RDL_in.len),
        .quotient_out(quotient_z),
        .valid_out(valid_z)
    );

    always_comb begin
        if(valid_x && valid_y && valid_z) begin
            valid_out = valid_x && valid_y && valid_z;
            normalized_ray_out = '{
                x : quotient_x,
                y : quotient_y,
                z : quotient_z
            };
        end else begin
            valid_out = 0;
            normalized_ray_out = '{
                x : 0,
                y : 0,
                z : 0
            };
        end
    end



endmodule