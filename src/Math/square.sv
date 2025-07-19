`timescale 1ns / 1ps
`include "Types.sv"

// normalizasyon icin yonlerin karesini alan 1 cycle modul
module tagged_pow #(
    parameter WIDTH  = `WIDTH,
    parameter Q_BITS = `Q_BITS,
)(
    input clk,
    input reset,
    input start,
    input logic signed [WIDTH-1:0] a_in,
    output logic valid_out,
    output logic signed [WIDTH-1:0] square_out
);

    logic [WIDTH+Q_BITS-1:0] pow_a;
    logic valid;

    always_ff @(posedge clk) begin
        if(reset) begin
            pow_a <= 0;
            valid <= 0;
        end else if (start) begin
            pow_a <= a_in * a_in;
            valid <= 1;
        end else begin
            valid <= 0;
            pow_a <= 0;
        end
    end

    assign square_out = pow_a;
    assign valid_out = valid;

endmodule
