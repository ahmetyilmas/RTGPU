`timescale 1ns / 1ps
`include "Types.sv"


module AABB #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter DIV_COUNT = 16,
    parameter MAX = `MAX_16,
    parameter MIN = `MIN_16,
    parameter TAG_SIZE = `TAG_SIZE
)(
    input clk,
    input reset,
    input start,
    input TaggedRay ray_in, // origin, direction, tag bilgileri
    input AABB aabb_box,    // min, max, color bilgileri
    output AABB_result test_result,
    output logic valid
);
    
    logic ray_hit_x,ray_hit_y,ray_hit_z;
    logic start_inv;

    always_comb begin
        if(start) begin
            if(ray_in.direction.x == 0) begin
                if(!(ray_in.origin.x >= aabb_box.min.x & ray_in.origin.x <= aabb_box.max.x))
                    ray_hit_x = 0;
                else
                    ray_hit_x = 1;
            end else
                ray_hit_x = 1;
    
            if(ray_in.direction.y == 0) begin
                if(!(ray_in.origin.y >= aabb_box.min.y & ray_in.origin.y <= aabb_box.max.y)) begin
                    ray_hit_y = 0;
                end else begin
                    ray_hit_y = 1;
                end 
            end else 
                ray_hit_y = 1;
            if(ray_in.direction.z == 0) begin
                if(!(ray_in.origin.z >= aabb_box.min.z & ray_in.origin.z <= aabb_box.max.z)) begin
                    ray_hit_z = 0;
                end else begin
                    ray_hit_z = 1;
                end
            end else
                ray_hit_z = 1;
            
            start_inv = 1;
        end
    end

    TaggedDirection dir_in;
    assign dir_in = '{
        direction : ray_in.direction,
        tag : ray_in.tag
    };

    TaggedDirection inv_dir;
    logic valid_inv;
    
    inverted_direction #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .TAG_SIZE(TAG_SIZE),
        .DIV_COUNT(DIV_COUNT)
    ) invert (
        .clk(clk),
        .reset(reset),
        .start(start_inv),
        .direction_in(dir_in),
        .inv_dir_out(inv_dir),
        .valid_out(valid_inv)
    );
    
    
    TaggedVec3 t_xyz_1;
    TaggedVec3 t_xyz_2;
    
    logic signed [WIDTH-1:0] mul_tx1, mul_tx2, mul_ty1, mul_ty2, mul_tz1, mul_tz2;
    logic signed [WIDTH-1:0] tx1, tx2, ty1, ty2, tz1, tz2;
    logic signed [WIDTH-1:0] tminx, tminy, tminz;
    logic signed [WIDTH-1:0] tmaxx, tmaxy, tmaxz;
    logic signed [WIDTH-1:0] tmin, tmax;
    logic signed [WIDTH-1:0] max_tmin;
    logic signed [WIDTH-1:0] tmin_out;
    
    
    logic ray_hit;
    logic [TAG_SIZE-1:0] tag_out; 

    logic valid_tx1, valid_tx2;
    logic valid_ty1, valid_ty2;
    logic valid_tz1, valid_tz2;
    logic valid_all;
    
    assign tx1 = aabb_box.min.x - ray_in.origin.x;
    assign tx2 = aabb_box.max.x - ray_in.origin.x;
    assign ty1 = aabb_box.min.y - ray_in.origin.y;
    assign ty2 = aabb_box.max.y - ray_in.origin.y;
    assign tz1 = aabb_box.min.z - ray_in.origin.z;
    assign tz2 = aabb_box.max.z - ray_in.origin.z;
    
    
    
    logic [1:0]t_calc_valid;
    
    t_calc #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS),
    .TAG_SIZE(TAG_SIZE)
    )t1 (
    .clk(clk),
    .start(valid_inv),
    .dir_in_a(inv_dir),
    .tx(tx1),
    .ty(ty1),
    .tz(tz1),
    .valid(t_calc_valid[0]),
    .TD_out(t_xyz_1)
    );
    
    t_calc #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS),
    .TAG_SIZE(TAG_SIZE)
    )t2 (
    .clk(clk),
    .start(valid_inv),
    .dir_in_a(inv_dir),
    .tx(tx2),
    .ty(ty2),
    .tz(tz2),
    .valid(t_calc_valid[1]),
    .TD_out(t_xyz_2)
    );
    
    assign mul_tx1 = (inv_dir.direction.x == MAX) ? MIN : t_xyz_1.x;
    assign mul_tx2 = (inv_dir.direction.x == MAX) ? MAX : t_xyz_2.x;
    assign mul_ty1 = (inv_dir.direction.y == MAX) ? MIN : t_xyz_1.y;
    assign mul_ty2 = (inv_dir.direction.y == MAX) ? MAX : t_xyz_2.y;
    assign mul_tz1 = (inv_dir.direction.z == MAX) ? MIN : t_xyz_1.z;
    assign mul_tz2 = (inv_dir.direction.z == MAX) ? MAX : t_xyz_2.z;

    assign tag_out = t_xyz_1.tag;

    assign valid_all = &t_calc_valid;
    
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

    assign test_result = '{
        box : aabb_box,
        ray_hit : ray_hit,
        tag : tag_out,
        tmin : tmin_out
    };
    
endmodule
