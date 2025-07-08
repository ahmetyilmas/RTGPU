`timescale 1ns / 1ps
`include "Types.sv"

    // ESKI FSM
module AABB #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS, // Q.3.12 format
    parameter MAX = `MAX_16,
    parameter MIN = `MIN_16
)(
    input clk,
    input start,
    input reset,
    input RayDirection direction,   // direction of the ray
    input RayOrigin origin,          // Starting position of the ray
    input Min min,
    input Max max,
    output state aabb_state,
    output logic ray_hit,
    output logic signed [WIDTH-1:0]tmin_out,
    output logic valid
);

    RayDirection normalized;
    wire valid_normal;
    logic start_norm;
    
    logic ray_hit_x,ray_hit_y,ray_hit_z;
    
    always_comb begin
        if(direction.x == 0) begin
            if(!(origin.x >= min.x & origin.x <= max.x))
                ray_hit_x = 0;
            else
                ray_hit_x = 1;
        end
            ray_hit_x = 1;

        if(direction.y == 0) begin
            if(!(origin.y >= min.y & origin.y <= max.y)) begin
                ray_hit_y = 0;
            end else begin
                ray_hit_y = 1;
            end
        end else begin
            ray_hit_y = 1;
        end
        if(direction.z == 0) begin
            if(!(origin.z >= min.z & origin.z <= max.z)) begin
                ray_hit_z = 0;
            end else begin
                ray_hit_z = 1;
            end
        end else begin
            ray_hit_z = 1;
        end
    end
    
    assign start_norm = start & ray_hit_x & ray_hit_y & ray_hit_z;

    
    normalization #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) normalize (
        .clk(clk),
        .reset(reset),
        .start(start_norm),
        .dir(direction),
        .normal(normalized),
        .valid_out(valid_normal)
    );
    
    InvertedRayDirection inv_dir;
    logic valid_inv;
    
    inverted_direction #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MAX(MAX)
    ) invert (
        .clk(clk),
        .reset(reset),
        .start(valid_normal),
        .norm_dir(normalized),
        .inv_dir(inv_dir),
        .valid_out(valid_inv)
    );
    
    logic signed [WIDTH-1:0] mul_tx1, mul_tx2, mul_ty1, mul_ty2, mul_tz1, mul_tz2;
    logic [WIDTH-1:0]mul_tx1_control;
    logic [WIDTH-1:0]mul_tx2_control;
    logic [WIDTH-1:0]mul_ty1_control;
    logic [WIDTH-1:0]mul_ty2_control;
    logic [WIDTH-1:0]mul_tz1_control;
    logic [WIDTH-1:0]mul_tz2_control;
    logic signed [WIDTH-1:0] tx1, tx2, ty1, ty2, tz1, tz2;
    logic signed [WIDTH-1:0] tminx, tminy, tminz;
    logic signed [WIDTH-1:0] tmaxx, tmaxy, tmaxz;
    logic signed [WIDTH-1:0] tmin, tmax;
    logic signed [WIDTH-1:0] max_tmin;
    
    logic valid_tx1, valid_tx2;
    logic valid_ty1, valid_ty2;
    logic valid_tz1, valid_tz2;
    logic valid_all;
    
    assign tx1 = min.x - origin.x;
    assign tx2 = max.x - origin.x;
    assign ty1 = min.y - origin.y;
    assign ty2 = max.y - origin.y;
    assign tz1 = min.z - origin.z;
    assign tz2 = max.z - origin.z;
    
    
    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) mulX1 (
        .clk(clk),
        .start(valid_inv),
        .reset(reset),
        .sqrt_state(IDLE),
        .a(tx1),
        .b(inv_dir.x),
        .next_start(valid_tx1),
        .result(mul_tx1_control)
    );
    
    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) mulX2 (
        .clk(clk),
        .start(valid_inv),
        .reset(reset),
        .sqrt_state(IDLE),
        .a(tx2),
        .b(inv_dir.x),
        .next_start(valid_tx2),
        .result(mul_tx2_control)
    );
    
    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) mulY1 (
        .clk(clk),
        .start(valid_inv),
        .reset(reset),
        .sqrt_state(IDLE),
        .a(ty1),
        .b(inv_dir.y),
        .next_start(valid_ty1),
        .result(mul_ty1_control)
    );
    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) mulY2 (
        .clk(clk),
        .start(valid_inv),
        .reset(reset),
        .sqrt_state(IDLE),
        .a(ty2),
        .b(inv_dir.y),
        .next_start(valid_ty2),
        .result(mul_ty2_control)
    );
    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) mulZ1 (
        .clk(clk),
        .start(valid_inv),
        .reset(reset),
        .sqrt_state(IDLE),
        .a(tz1),
        .b(inv_dir.z),
        .next_start(valid_tz1),
        .result(mul_tz1_control)
    );
    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) mulZ2 (
        .clk(clk),
        .start(valid_inv),
        .reset(reset),
        .sqrt_state(IDLE),
        .a(tz2),
        .b(inv_dir.z),
        .next_start(valid_tz2),
        .result(mul_tz2_control)
    );
    

    assign mul_tx1 = (inv_dir.x == MAX) ? MIN : mul_tx1_control;
    assign mul_tx2 = (inv_dir.x == MAX) ? MAX : mul_tx2_control;
    assign mul_ty1 = (inv_dir.y == MAX) ? MIN : mul_ty1_control;
    assign mul_ty2 = (inv_dir.y == MAX) ? MAX : mul_ty2_control;
    assign mul_tz1 = (inv_dir.z == MAX) ? MIN : mul_tz1_control;
    assign mul_tz2 = (inv_dir.z == MAX) ? MAX : mul_tz2_control;


    assign valid_all = valid_tx1 & valid_tx2 & valid_ty1 & valid_ty2 & valid_tz1 & valid_tz2;
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            ray_hit <= 0;
            tmin_out <= 0;
            valid <= 0;
        end else if(valid_all) begin
            tminx = (mul_tx1 < mul_tx2) ? mul_tx1 : mul_tx2;
            tmaxx = (mul_tx1 > mul_tx2) ? mul_tx1 : mul_tx2;
            tminy = (mul_ty1 < mul_ty2) ? mul_ty1 : mul_ty2;
            tmaxy = (mul_ty1 > mul_ty2) ? mul_ty1 : mul_ty2;
            tminz = (mul_tz1 < mul_tz2) ? mul_tz1 : mul_tz2;
            tmaxz = (mul_tz1 > mul_tz2) ? mul_tz1 : mul_tz2;
    
            tmin = (tminx > tminy) ? ((tminx > tminz) ? tminx : tminz) : ((tminy > tminz) ? tminy : tminz);
            tmax = (tmaxx < tmaxy) ? ((tmaxx < tmaxz) ? tmaxx : tmaxz) : ((tmaxy < tmaxz) ? tmaxy : tmaxz);
            
            
            max_tmin = (tmin >= 0) ? tmin : 0;
            ray_hit = (tmax >= max_tmin);
            tmin_out = ray_hit ? max_tmin : 0;
            valid <= 1;
        end else if (!ray_hit_x || !ray_hit_y || !ray_hit_z) begin
            ray_hit = 0;
            valid <= 1;
        end else begin
            valid <= 0;
        end
    end

    
    
endmodule
