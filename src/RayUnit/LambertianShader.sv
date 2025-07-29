`timescale 1ns/1ps
`include "../Types.sv"
`include "../Parameters.sv"

/*
    Q11.12, 8 bit RGB icin sentez sonuclari:
    LUT:277,
    FF: 17,
    DSP:12
*/

module LambertianShader #(
    parameter int WIDTH = 24,
    parameter int Q_BITS = 12,
    parameter int RGB_WIDTH = 8
)(
    input clk,
    input reset,
    input start,
    input AABB_result_t aabb_in,          // AABB nesnesinin bilgileri
    input LightSource_t lightSource_in,
    output Color finalColor_out,
    output logic valid_out
);

        logic signed [WIDTH-1:0]dot_x;
        logic signed [WIDTH-1:0]dot_y;
        logic signed [WIDTH-1:0]dot_z;

        logic signed [WIDTH-1:0] sum;
        logic signed [WIDTH-1:0] dot; // dot = (Nx*Lx)+(Ny*Ly)+(Nz*Lz)

        Color finalColor;
        Color AABB_color;
        Color light_color;

        wire [WIDTH-1:0] normal_x, normal_y, normal_z;
        wire [WIDTH-1:0] dir_x   , dir_y   , dir_z;

        assign normal_x = aabb_in.normal.x;
        assign normal_y = aabb_in.normal.y;
        assign normal_z = aabb_in.normal.z;

        assign dir_x = lightSource_in.ray.direction.x;
        assign dir_y = lightSource_in.ray.direction.y;
        assign dir_z = lightSource_in.ray.direction.z;

        assign AABB_color = aabb_in.box.color;
        assign light_color = lightSource_in.ray_color;


        // Stage 1: N*L ve rgb*rgb carpimlarini yap

        logic [5:0]stage_1_valid;

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) mulx (
            .clk(clk),
            .start(start),
            .a(normal_x),
            .b(dir_x),
            .result(dot_x),
            .valid(stage_1_valid[0])
        );
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) muly (
            .clk(clk),
            .start(start),
            .a(normal_y),
            .b(dir_y),
            .result(dot_y),
            .valid(stage_1_valid[1])
        );
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) mulz (
            .clk(clk),
            .start(start),
            .a(normal_z),
            .b(dir_z),
            .result(dot_z),
            .valid(stage_1_valid[2])
        );

        logic [WIDTH-1:0] rr_result;
        logic [WIDTH-1:0] gg_result;
        logic [WIDTH-1:0] bb_result;

        rgb_multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS),
            .RGB_WIDTH(RGB_WIDTH)
        ) rr_mul (
            .clk(clk),
            .start(start),
            .a_in(light_color.r),
            .b_in(AABB_color.r),
            .result_out(rr_result),
            .valid_out(stage_1_valid[3])
        );

        rgb_multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS),
            .RGB_WIDTH(RGB_WIDTH)
        ) gg_mul (
            .clk(clk),
            .start(start),
            .a_in(light_color.g),
            .b_in(AABB_color.g),
            .result_out(gg_result),
            .valid_out(stage_1_valid[4])
        );
        rgb_multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS),
            .RGB_WIDTH(RGB_WIDTH)
        ) bb_mul (
            .clk(clk),
            .start(start),
            .a_in(light_color.b),
            .b_in(AABB_color.b),
            .result_out(bb_result),
            .valid_out(stage_1_valid[5])
        );

        assign sum = &stage_1_valid ? dot_x + dot_y + dot_z: 0;


        assign dot = sum < 0 ? 0 : sum;


        logic stage_2_start = &stage_1_valid;

        // Stage 2: dot * rgb_result

        logic [2:0]stage_2_valid;

        logic [WIDTH-1:0]red;
        logic [WIDTH-1:0]blue;
        logic [WIDTH-1:0]green;

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) rdot (
            .clk(clk),
            .start(stage_2_start),
            .a(rr_result),
            .b(dot),
            .result(red),
            .valid(stage_2_valid[0])
        );
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) gdot (
            .clk(clk),
            .start(stage_2_start),
            .a(gg_result),
            .b(dot),
            .result(green),
            .valid(stage_2_valid[1])
        );
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) bdot (
            .clk(clk),
            .start(stage_2_start),
            .a(bb_result),
            .b(dot),
            .result(blue),
            .valid(stage_2_valid[2])
        );

        always_comb begin
            if(&stage_2_valid) begin
                finalColor_out = '{
                    r: red  [Q_BITS+RGB_WIDTH-1:Q_BITS],
                    g: green[Q_BITS+RGB_WIDTH-1:Q_BITS],
                    b: blue [Q_BITS+RGB_WIDTH-1:Q_BITS]
                };
                valid_out = 1;
            end else begin
                finalColor_out = '{
                    r: 8'h00,
                    g: 8'h00,
                    b: 8'h00
                };
                valid_out = 0;
            end
        end


endmodule
