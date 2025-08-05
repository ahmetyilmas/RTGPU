`timescale 1ns/1ps
`include "Types.sv"
`include "Parameters.sv"

/*
Bu modül AABB testi yapıldıktan sonra gölge ekleyebilmek için yeni bir Ray oluşturmada kullanılır.
Eğer AABB testinde hit = 0 ise modülün çalışmasına gerek yoktur fakat hit = 1 ise hit_point'e göre yeni
*/

module ShadowRayGenerator #(
    parameter int WIDTH = 24,
    parameter int Q_BITS = 12
) (
    input clk,
    input reset,
    input start,
    input AABB_result_t test_result,
    input LightSource_t light_source,
    input Vec3_t hit_point,

    output valid,
    output Ray shadow_ray
);

    localparam logic EPSILON = EPSILON_24;

    wire start_mul;
    assign start_mul = start;

    logic [2:0] mul_valid;

//  Stage 1: ε * normal

    logic [WIDTH-1:0] eps_x;
    logic [WIDTH-1:0] eps_y;
    logic [WIDTH-1:0] eps_z;

    Vec3_t hit_point_ff;

    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) x (
        .clk(clk),
        .start(start_mul),
        .a(test_result.normal.x),
        .b(EPSILON),
        .valid(mul_valid[0]),
        .result(eps_x)
    );

    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) y (
        .clk(clk),
        .start(start_mul),
        .a(test_result.normal.y),
        .b(EPSILON),
        .valid(mul_valid[1]),
        .result(eps_y)
    );

    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) z (
        .clk(clk),
        .start(start_mul),
        .a(test_result.normal.z),
        .b(EPSILON),
        .valid(mul_valid[2]),
        .result(eps_z)
    );

    always_ff @( posedge clk or posedge reset) begin
        if(reset) begin
            hit_point_ff <= 0;
        end else begin
            if(start) begin
                hit_point_ff <= hit_point;
            end
        end
    end

// Stage 2: offset_origin = eps_xyz + hit_point
//          direction_vec = light_pos - hit_point

    RayOrigin offset_origin;
    RayOrigin offset_origin_ff;

    Vec3_t direction_vec;
    Vec3_t direction_vec_ff;

    logic writeff;

    always_comb begin
        if(&mul_valid) begin
            offset_origin.x = hit_point_ff + eps_x;
            offset_origin.y = hit_point_ff + eps_y;
            offset_origin.z = hit_point_ff + eps_z;

            direction_vec.x = light_source.min_x - hit_point_ff.x;
            direction_vec.y = light_source.min_y - hit_point_ff.y;
            direction_vec.z = light_source.min_z - hit_point_ff.z;

            writeff = 1;
        end else begin
            offset_origin.x = 0;
            offset_origin.y = 0;
            offset_origin.z = 0;

            direction_vec.x = 0;
            direction_vec.y = 0;
            direction_vec.z = 0;

            writeff = 0;
        end
    end

    always_ff @( posedge clk ) begin
        if(writeff) begin
            offset_origin_ff.x <= offset_origin.x;
            offset_origin_ff.y <= offset_origin.y;
            offset_origin_ff.z <= offset_origin.z;
        end else begin
            offset_origin_ff.x <= 0;
            offset_origin_ff.y <= 0;
            offset_origin_ff.z <= 0;
        end
    end

// Stage 3: normalize(direction_vec)


endmodule
