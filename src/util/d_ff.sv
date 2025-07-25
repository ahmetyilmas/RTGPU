`timescale 1ns/1ps

module d_ff#(
    parameter int WIDTH = `WIDTH
)(
    input clk,
    input reset,
    input logic [WIDTH-1:0]d_in,
    output logic [WIDTH-1:0]q_out
);
    logic [WIDTH-1:0]q_ff;

    always_ff @(posedge clk) begin
        if(reset) begin
            q_ff <= 0;
        end else begin
            q_ff <= d_in;
        end
    end

    assign q_out = q_ff;

endmodule
