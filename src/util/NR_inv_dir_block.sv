`timescale 1ns / 1ps
`include "Types.sv"

// 1/dir icin birlestirilmis x,y,z kordinatlarini hesaplayacak divider blogu

module NR_inv_dir_block #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS,   // Q3.12
    parameter MAX    = `MAX_16,
    parameter MIN    = `MIN_16
    )(
    
    input clk,
    input start,
    input reset,
    input skip_in,
    input RayDirection RD_in,

    output RayDirection RD_out,
    output logic skip_out,
    output logic valid_out
    );

    localparam MSB = WIDTH+Q_BITS-1;
    localparam LSB = 0;

    logic [WIDTH+Q_BITS:0] skip_flag;
    
    always_ff @(posedge clk) begin
        if(reset) begin
            skip_flag <= 0;
        end else begin
                skip_flag <= {skip_flag[MSB-1:LSB], skip_in};
        end
    end
    
    logic valid_x, valid_y, valid_z;

    wire [WIDTH-1:0]quotient_x;
    wire [WIDTH-1:0]quotient_y;
    wire [WIDTH-1:0]quotient_z;

    non_restoring_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MAX(MAX),
        .MIN(MIN)
    ) NRD_X (
        .clk(clk),
        .reset(reset),
        .start(start),
        .dividend_in({4'b0001, {(WIDTH-4){1'b0}}}),
        .divisor_in(RD_in.x),
        .quotient_out(quotient_x),
        .valid_out(valid_x)
    );
    non_restoring_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MAX(MAX),
        .MIN(MIN)
    ) NRD_Y (
        .clk(clk),
        .reset(reset),
        .start(start),
        .dividend_in({4'b0001, {(WIDTH-4){1'b0}}}),
        .divisor_in(RD_in.y),
        .quotient_out(quotient_y),
        .valid_out(valid_y)
    );
    non_restoring_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MAX(MAX),
        .MIN(MIN)
    ) NRD_Z (
        .clk(clk),
        .reset(reset),
        .start(start),
        .dividend_in({4'b0001, {(WIDTH-4){1'b0}}}),
        .divisor_in(RD_in.z),
        .quotient_out(quotient_z),
        .valid_out(valid_z)
    );

     always_comb begin
        if(valid_x && valid_y && valid_z) begin
            valid_out = valid_x && valid_y && valid_z;
            RD_out = '{
                x : quotient_x,
                y : quotient_y,
                z : quotient_z
            };
            skip_out = skip_flag[MSB];
        end else begin
            valid_out = 0;
            RD_out = '{
                x : 0,
                y : 0,
                z : 0
            };
            skip_out = 0;
        end
    end
endmodule