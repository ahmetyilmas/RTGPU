`timescale 1ns / 1ps
`include "Types.sv"

// dir * float carpimini 1 clk'da veren modul
module t_calc #(
    parameter WIDTH  = `WIDTH,
    parameter Q_BITS = `Q_BITS
)(
    input clk,
    input start,
    input skip_in,
    input RayDirection RD_in,
    input logic signed [WIDTH-1:0] tx,
    input logic signed [WIDTH-1:0] ty,
    input logic signed [WIDTH-1:0] tz,
    output logic skip_out,
    output logic valid_out,
    output RayDirection RD_out
);
    
    RayDirection RD_ff;
    logic skip;
    logic valid;

    logic signed [WIDTH-1:0] a_x;
    logic signed [WIDTH-1:0] a_y;
    logic signed [WIDTH-1:0] a_z;
    
    assign a_x = RD_in.x;
    assign a_y = RD_in.y;
    assign a_z = RD_in.z;
    
    
    logic signed [2*WIDTH-1:0]res_x;
    logic signed [2*WIDTH-1:0]res_y;
    logic signed [2*WIDTH-1:0]res_z;
    
    assign res_x = a_x * tx;
    assign res_y = a_y * ty;
    assign res_z = a_z * tz;
    
    always_ff @(posedge clk) begin
        if (start) begin
            RD_ff.x <= res_x[WIDTH+Q_BITS-1:Q_BITS];
            RD_ff.y <= res_y[WIDTH+Q_BITS-1:Q_BITS];
            RD_ff.z <= res_z[WIDTH+Q_BITS-1:Q_BITS];
            skip <= skip_in;
            valid <= 1;
        end else begin
            RD_ff.x <= 0;
            RD_ff.y <= 0;
            RD_ff.z <= 0;
            skip <= 0;
            valid <= 0;
        end
    end

    assign RD_out = RD_ff;
    assign skip_out = skip;
    assign valid_out = valid;
endmodule
