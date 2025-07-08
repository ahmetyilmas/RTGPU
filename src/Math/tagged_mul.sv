`timescale 1ns / 1ps
`include "Types.sv"

// normalizasyon icin yonlerin karesini alan 1 cycle modul
module tagged_mul #(
    parameter WIDTH  = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter TAG_SIZE = 64
)(
    input clk,
    input start,
    input TaggedDirection dir_in,
    output valid,
    output TaggedDirection_pow TDP_out
);

    logic valid_ff;
        
    logic signed [WIDTH-1:0]x;
    logic signed [WIDTH-1:0]y;
    logic signed [WIDTH-1:0]z;
    
    logic signed [2*WIDTH-1:0]pow_x;
    logic signed [2*WIDTH-1:0]pow_y;
    logic signed [2*WIDTH-1:0]pow_z;
    
    assign x = dir_in.direction.x;
    assign y = dir_in.direction.y;
    assign z = dir_in.direction.z;
    
    assign pow_x = x * x;
    assign pow_y = y * y;
    assign pow_z = z * z;
    
    always_ff @(posedge clk) begin
        TDP_out.direction <= dir_in;
        TDP_out.pow.x <= pow_x[WIDTH+Q_BITS-1:Q_BITS];
        TDP_out.pow.y <= pow_y[WIDTH+Q_BITS-1:Q_BITS];
        TDP_out.pow.z <= pow_z[WIDTH+Q_BITS-1:Q_BITS];
        valid_ff <= start;
    end
endmodule
