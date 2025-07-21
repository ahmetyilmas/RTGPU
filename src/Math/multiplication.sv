`timescale 1ns / 1ps
`include "Types.sv"

// 1 cycle multiplier
module multiplication #(
    parameter WIDTH  = `WIDTH,
    parameter Q_BITS = `Q_BITS
)(
    input start,
    input clk,
    input signed [WIDTH-1:0]a,
    input signed [WIDTH-1:0]b,
    output valid,
    output logic signed [WIDTH-1:0]result
);

    logic [2*WIDTH-1:0]result_ff;
    logic valid_ff;
    
    always @(posedge clk) begin
        result_ff <= a * b;
        valid_ff <= start;
    end
    assign result[WIDTH-1:0] = result_ff[WIDTH+Q_BITS-1:Q_BITS];
    assign valid = valid_ff;
endmodule
