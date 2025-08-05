`timescale 1ns/1ps
`include "Parameters.sv"
`include "Types.sv"

module ShadowCore #(
    parameter int WIDTH = 20,
    parameter int QBITS = 12
) (
    input clk,
    input reset,
    input start,
    input Cam_t camera,
    input AABB_result_t aabb_result
);


endmodule
