`timescale 1ns/1ps
`include "Types.sv"
`include "Parameters.sv"

module rgb_multiplication #(
    parameter int WIDTH = 24,
    parameter int Q_BITS = 12,
    parameter int RGB_WIDTH = 8
)(
    input clk,
    input start,
    input unsigned  [RGB_WIDTH-1:0] a_in,
    input unsigned  [RGB_WIDTH-1:0] b_in,
    output logic signed [WIDTH-1:0] result_out,
    output valid_out
);

    logic [2*RGB_WIDTH-1:0]result_ff;
    logic valid_ff;

    always @(posedge clk) begin
        if(start) begin
            result_ff <= a_in * b_in;
            valid_ff <= 1;
        end else begin
            result_ff <= 0;
            valid_ff <= 0;
        end
    end

    assign result_out = 
    {{(WIDTH-(Q_BITS+RGB_WIDTH)){1'b0}}, result_ff[2*RGB_WIDTH-1:RGB_WIDTH], {(Q_BITS){1'b0}}};

    assign valid_out = valid_ff;

endmodule
