`timescale 1ns/1ps
`include "Types.sv"

module PrimitiveUnit #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS, // Q.3.12 format
    parameter DIV_COUNT = 16
)
(
    input clk,
    input reset,
    input start,
    input SceneObject object,
    input TaggedRay ray_in,
    output AABB_result result
);

    localparam  MAX = `MAX_16;
    localparam  MIN = `MIN_16;
    localparam CORE_COUNT = `BOX_COUNT;




    logic [CORE_COUNT-1:0] core_valid;
    AABB_result [CORE_COUNT-1:0] test_result;

    genvar i;
    generate
        for(i = 0; i < CORE_COUNT; i++) begin
            AABB #(
                .WIDTH(WIDTH),
                .Q_BITS(Q_BITS),
                .DIV_COUNT(DIV_COUNT),
                .MAX(MAX),
                .MIN(MIN)
            ) AABB_CORE (
                .clk(clk),
                .reset(reset),
                .start(start),
                .ray_in(ray_in),
                .aabb_box(object.box[i]),
                .test_result(test_result[i]),
                .valid(core_valid[i])
            );
        end
    endgenerate

endmodule