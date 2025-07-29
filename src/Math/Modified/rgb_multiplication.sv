`timescale 1ns/1ps
`include "../Types.sv"
`include "../Parameters.sv"

module rgb_multiplication (
    input clk,
    input start,
    input [7:0]a,
    input [7:0]b,
    output logic [7:0]result,
    output valid
);

    logic [15:0]result_ff;
    logic valid_ff;

    always @(posedge clk) begin
        result_ff <= a * b;
        valid_ff <= start;
    end

    assign result = result_ff[15:8];
    assign valid = valid_ff;

endmodule
