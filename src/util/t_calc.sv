`timescale 1ns / 1ps
`include "Types.sv"

// tagged dir * normal sayi carpimini 1 cycle ile veren modul
module t_calc #(
    parameter WIDTH  = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter TAG_SIZE = 48
)(
    input clk,
    input start,
    input TaggedDirection dir_in_a,
    input logic signed [WIDTH-1:0] tx,
    input logic signed [WIDTH-1:0] ty,
    input logic signed [WIDTH-1:0] tz,
    output logic valid,
    output TaggedDirection TD_out
);
    
    logic signed [WIDTH-1:0] a_x;
    logic signed [WIDTH-1:0] a_y;
    logic signed [WIDTH-1:0] a_z;
    
    assign a_x = dir_in_a.direction.x;
    assign a_y = dir_in_a.direction.y;
    assign a_z = dir_in_a.direction.z;
    
    
    logic signed [2*WIDTH-1:0]res_x;
    logic signed [2*WIDTH-1:0]res_y;
    logic signed [2*WIDTH-1:0]res_z;
    
    assign res_x = a_x * tx;
    assign res_y = a_y * ty;
    assign res_z = a_z * tz;
    
    always_ff @(posedge clk) begin
        if (start) begin
            TD_out.tag <= dir_in_a.tag;
            TD_out.direction.x <= res_x[WIDTH+Q_BITS-1:Q_BITS];
            TD_out.direction.y <= res_y[WIDTH+Q_BITS-1:Q_BITS];
            TD_out.direction.z <= res_z[WIDTH+Q_BITS-1:Q_BITS];
            valid <= 1;
        end else begin
            valid <= 0;
        end
    end
endmodule
