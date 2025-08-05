`timescale 1ns/1ps
`include "Types.sv"
`include "Parameters.sv"

/*
Bu modül AABB testi yapıldıktan sonra gölge ekleyebilmek için yeni bir Ray oluşturmada kullanılır.
Eğer AABB testinde hit = 0 ise modülün çalışmasına gerek yoktur fakat hit = 1 ise hit_point'e göre yeni
bir origin oluşturulur ve ışık kaynağının konumu ve hit_point'e göre bir shadow_ray atılır.
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




endmodule
