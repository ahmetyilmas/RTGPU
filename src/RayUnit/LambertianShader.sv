`timescale 1ns/1ps
`include "../Types.sv"
`include "../Parameters.sv"

/*
    Q11.12 icin sentez sonuclari:
    LUT:251
    DSP:3
*/

module LambertianShader #(
    parameter int WIDTH = 24,
    parameter int Q_BITS = 12
)(
    input clk,
    input reset,
    input start,
    input AABB_result_t aabb_in,          // AABB nesnesinin bilgileri
    input RayDirection light_direction_in,// Gelen isin yonu
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

        assign dir_x = light_direction_in.x;
        assign dir_y = light_direction_in.y;
        assign dir_z = light_direction_in.z;

        assign AABB_color = aabb_in.box.color;
        assign light_color = lightSource_in.ray_color;


        // Stage 1: (Nx*Lx)+(Ny*Ly)+(Nz*Lz)

        logic [2:0]stage_1_valid;

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

        assign sum = &stage_1_valid ? dot_x + dot_y + dot_z: 0;


        assign dot = sum < 0 ? 0 : sum;

        // 8 bit RGB degerlerini kullanilan Q formata cevir

        logic signed [WIDTH-1:0] light_rq;
        logic signed [WIDTH-1:0] light_gq;
        logic signed [WIDTH-1:0] light_bq;
        logic signed [WIDTH-1:0] aabb_rq;
        logic signed [WIDTH-1:0] aabb_gq;
        logic signed [WIDTH-1:0] aabb_bq;

        logic rgbq_valid;

        always_ff @(posedge clk) begin
            if(reset) begin
                light_rq   <= 0;
                light_gq   <= 0;
                light_bq   <= 0;
                aabb_rq    <= 0;
                aabb_gq    <= 0;
                aabb_bq    <= 0;
                rgbq_valid <= 0;
            end else begin
                light_rq[WIDTH-8:Q_BITS] <= light_color.r;
                light_gq[WIDTH-8:Q_BITS] <= light_color.g;
                light_bq[WIDTH-8:Q_BITS] <= light_color.b;
                aabb_rq [WIDTH-8:Q_BITS] <= AABB_color.r;
                aabb_gq [WIDTH-8:Q_BITS] <= AABB_color.g;
                aabb_bq [WIDTH-8:Q_BITS] <= AABB_color.b;
                rgbq_valid <= 1;
            end
        end

        logic stage_2_start = rgbq_valid & (&stage_1_valid);

        // Stage 2: r*r, g*g, b*b carpimlarini yap ve onceki
        // etapta hesaplanan dot degerini ff'e at

        logic [2:0]stage_2_valid;

        logic [WIDTH-1:0] rr_result;
        logic [WIDTH-1:0] gg_result;
        logic [WIDTH-1:0] bb_result;

        logic [WIDTH-1:0]dot_ff_out;

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) mulr (
            .clk(clk),
            .start(stage_2_start),
            .a(light_rq),
            .b(aabb_rq),
            .result(rr_result),
            .valid(stage_2_valid[0])
        );
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) mulg (
            .clk(clk),
            .start(stage_2_start),
            .a(light_gq),
            .b(aabb_gq),
            .result(gg_result),
            .valid(stage_2_valid[1])
        );
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) mulb (
            .clk(clk),
            .start(stage_2_start),
            .a(light_bq),
            .b(aabb_bq),
            .result(bb_result),
            .valid(stage_2_valid[2])
        );

        d_ff #(
            .WIDTH(WIDTH)
        )(
            .clk(stage_2_start & clk),
            .reset(reset),
            .data_in(dot),
            .q_out(dot_ff_out)
        );

        logic stage_3_start = &stage_2_valid;

        // Stage 3: dot * rgb_result

        logic [3:0]stage_3_valid;

        logic [WIDTH-1:0]red;
        logic [WIDTH-1:0]blue;
        logic [WIDTH-1:0]green;

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) rdot (
            .clk(clk),
            .start(stage_3_start),
            .a(rr_result),
            .b(dot_ff_out),
            .result(red),
            .valid(stage_3_valid[0])
        );
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) gdot (
            .clk(clk),
            .start(stage_3_start),
            .a(gg_result),
            .b(dot_ff_out),
            .result(green),
            .valid(stage_3_valid[1])
        );
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) bdot (
            .clk(clk),
            .start(stage_3_start),
            .a(bb_result),
            .b(dot_ff_out),
            .result(blue),
            .valid(stage_3_valid[2])
        );

        always_comb begin
            if(&stage_3_valid) begin
                finalColor_out = '{
                    r: red  [WIDTH-1:WIDTH-8],
                    g: green[WIDTH-1:WIDTH-8],
                    b: blue [WIDTH-1:WIDTH-8]
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
