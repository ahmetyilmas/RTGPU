`timescale 1ns / 1ps
`include "Types.sv"
module sqroot #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS
    )(
    input clk,
    input start,
    input logic [WIDTH-1:0]x_in,
    output logic valid_out,
    output [WIDTH-1:0]x_out
    );
    
    logic valid;
    logic valid_ff;
    logic [WIDTH+Q_BITS-1:0]x_in_ext;
    assign x_in_ext = {x_in,{Q_BITS{1'b0}}};
    
    
    cordic_0 sqrt_core (
            .aclk(clk),
            .s_axis_cartesian_tdata(x_in_ext),
            .s_axis_cartesian_tvalid(start),
            .m_axis_dout_tdata(x_out),
            .m_axis_dout_tvalid(valid)
        );

    assign valid_out = valid;
endmodule
