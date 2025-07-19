`timescale 1ns/1ps
`include "Types.sv"

module direction_square #(
    parameter WIDTH  = `WIDTH,
    parameter Q_BITS = `Q_BITS
)(
    input clk,
    input start,
    input RayDirection RD_in,
    output logic valid_out,
    output RayDirection_sqr RDS_out
);

    RayDirection_sqr RDS_ff;
    logic valid_ff;

    logic signed [WIDTH-1:0]x;
    logic signed [WIDTH-1:0]y;
    logic signed [WIDTH-1:0]z;
    
    logic signed [2*WIDTH-1:0]sqr_x;
    logic signed [2*WIDTH-1:0]sqr_y;
    logic signed [2*WIDTH-1:0]sqr_z;
    

    assign x = RD_in.x;
    assign y = RD_in.y;
    assign z = RD_in.z;
    
    assign sqr_x = x * x;
    assign sqr_y = y * y;
    assign sqr_z = z * z;
    
    always_ff @(posedge clk) begin
        if (start) begin
            RDS_ff = '{
                x : RD_in.x,
                y : RD_in.y,
                z : RD_in.z,

                sqr_x : sqr_x,
                sqr_y : sqr_y,
                sqr_z : sqr_z
            };
            valid_ff <= 1;
        end else begin
            RDS_ff = '{
                x : 0,
                y : 0,
                z : 0,

                sqr_x : 0,
                sqr_y : 0,
                sqr_z : 0
            };
            valid_ff <= 0;
        end
    end

    assign RDS_out = RDS_ff;
    assign valid_out = valid_ff;
    
endmodule