`timescale 1ns / 1ps
`include "Types.sv"


module AABB #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS, // Q.3.12 format
    parameter DIV_COUNT = 16,
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
    output logic ray_hit,
    output logic signed [WIDTH-1:0]tmin_out,
    output logic valid
);
    localparam TAG_SIZE = `TAG_SIZE;
    
    
    logic [TAG_SIZE-1:0] tag_used; // 48 bit: Her tag için 1-bit
    
    TaggedDirection taggedDir;
    TaggedDirection taggedDir_ff;
    logic tag_valid;
    
    // Tag atanirken:
    always_ff @(posedge clk) begin
        if(reset) begin
            tag_used <= 0;
            tag_valid <= 0;
        end else if (start) begin
            tag_valid <= 0;
            for (int i = 0; i < TAG_SIZE; i++) begin
                if (!tag_used[i]) begin
                    tag_used[i] <= 1;
                    //taggedDir.tag <= tag_used;
                    taggedDir_ff.direction <= direction;
                    tag_valid <= 1;
                    break;
                end
            end
        end else begin
            tag_valid <= 0;
        end
    end
    
    assign taggedDir.tag = tag_valid ? tag_used : 0;
    assign taggedDir.direction = tag_valid ? taggedDir_ff.direction : 0;
    
    
    logic ray_hit_x,ray_hit_y,ray_hit_z;
    
    always_comb begin
        if(tag_valid) begin
            if(taggedDir.direction.x == 0) begin
                if(!(origin.x >= min.x & origin.x <= max.x))
                    ray_hit_x = 0;
                else
                    ray_hit_x = 1;
            end else
                ray_hit_x = 1;
    
            if(taggedDir.direction.y == 0) begin
                if(!(origin.y >= min.y & origin.y <= max.y)) begin
                    ray_hit_y = 0;
                end else begin
                    ray_hit_y = 1;
                end 
            end else 
                ray_hit_y = 1;
            if(taggedDir.direction.z == 0) begin
                if(!(origin.z >= min.z & origin.z <= max.z)) begin
                    ray_hit_z = 0;
                end else begin
                    ray_hit_z = 1;
                end
            end else
                ray_hit_z = 1;
        end
    end

    TaggedDirection inv_dir;
    logic valid_inv;
    
    inverted_direction #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .TAG_SIZE(`TAG_SIZE),
        .DIV_COUNT(DIV_COUNT)
    ) invert (
        .clk(clk),
        .reset(reset),
        .start(tag_valid),
        .direction_in(taggedDir),
        .inv_dir_out(inv_dir),
        .valid_out(valid_inv)
    );
    
    
    TaggedVec3 t_xyz_1;
    TaggedVec3 t_xyz_2;
    logic [TAG_SIZE-1:0]tag_release;
    
    logic signed [WIDTH-1:0] mul_tx1, mul_tx2, mul_ty1, mul_ty2, mul_tz1, mul_tz2;
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
            tag_release <= t_xyz_1.tag;
            valid <= 1;
        end else if (!ray_hit_x || !ray_hit_y || !ray_hit_z) begin
            ray_hit = 0;
            valid <= 1;
            tag_release <= inv_dir.tag;
        end else begin
            valid <= 0;
        end
    end

    always_ff @(posedge clk) begin
        if (valid) begin
            tag_used <= tag_used & ~tag_release;
        end
    end
    
endmodule
