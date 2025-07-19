`timescale 1ns/1ps
`include "Types.sv"
/*
    16 WIDTH, 12 Q_BITS icin sentez sonuclari
    1673 LUT,
    1300 FF, 
    28 LUTRAM
*/
module non_restoring_divider #(
    WIDTH  = `WIDTH,
    Q_BITS = `Q_BITS,
    MAX    = `MAX_16,
    MIN    = `MIN_16
)(
    input clk,
    input reset,
    input start,
    input  logic signed [WIDTH-1:0]dividend_in, // Q
    input  logic signed [WIDTH-1:0]divisor_in,  // M
    output logic signed [WIDTH-1:0]quotient_out,
    output logic valid_out
);
    localparam MSB = WIDTH+Q_BITS-1;
    localparam LSB = 0;
    localparam SHIFT_COUNT = Q_BITS;
    localparam BIT_COUNT = WIDTH+Q_BITS;
    
    logic signed [BIT_COUNT-1:0] dividend_shifted;
        logic signed [BIT_COUNT-1:0] divisor_shifted;
        
        assign dividend_shifted = dividend_in << SHIFT_COUNT;
        assign divisor_shifted  = divisor_in;
        
        logic dividend_sign;
        logic divisor_sign;
        logic divisor_zero;
        
        assign dividend_sign = dividend_in[WIDTH-1];
        assign divisor_sign  = divisor_in[WIDTH-1];
        assign divisor_zero = ~(|divisor_in);
        
        logic signed [BIT_COUNT-1:0] dividend_comp;
        logic signed [BIT_COUNT-1:0] divisor_comp;
        
        always_comb begin
            if(divisor_sign) begin
                divisor_comp = -divisor_shifted;
            end else begin
                divisor_comp =  divisor_shifted;
            end
            if(dividend_sign) begin
                dividend_comp = -dividend_shifted;
            end else begin
                dividend_comp =  dividend_shifted;
            end
        end
    
    logic signed [BIT_COUNT-1:0] A_REG_OUT  [BIT_COUNT:1];
    logic signed [BIT_COUNT-1:0] Q_REG_OUT  [BIT_COUNT:1];
    logic signed [BIT_COUNT-1:0] M_REG_OUT  [BIT_COUNT:1];
    logic signed              SIGN_REG_OUT  [BIT_COUNT:1];
    logic                     START_REG_OUT [BIT_COUNT:1];
    logic                     ZERO_REG_OUT  [BIT_COUNT:1];
    
    d_ff #(
        .WIDTH(BIT_COUNT)
    ) A_REG0 (
        .clk(clk),
        .reset(reset),
        .data_in({BIT_COUNT{1'b0}}),
        .q_out(A_REG_OUT[1])
    );
    d_ff #(
        .WIDTH(BIT_COUNT)
    ) Q_REG0 (
        .clk(clk),
        .reset(reset),
        .data_in(dividend_comp),
        .q_out(Q_REG_OUT[1])
    );
    d_ff #(
        .WIDTH(BIT_COUNT)
    ) M_REG0 (
        .clk(clk),
        .reset(reset),
        .data_in(divisor_comp),
        .q_out(M_REG_OUT[1])
    );
    d_ff #(
        .WIDTH(1)
    ) SIGN_REG0 (
        .clk(clk),
        .reset(reset),
        .data_in(dividend_sign ^ divisor_sign),
        .q_out(SIGN_REG_OUT[1])
    );
    d_ff #(
        .WIDTH(1)
    ) START_REG0 (
        .clk(clk),
        .reset(reset),
        .data_in(start),
        .q_out(START_REG_OUT[1])
    );
    d_ff #(
        .WIDTH(1)
    ) ZERO_REG0 (
        .clk(clk),
        .reset(reset),
        .data_in(divisor_zero),
        .q_out(ZERO_REG_OUT[1])
    );
    
    logic signed [BIT_COUNT-1:0] A1_WIRE [BIT_COUNT:1];
    logic signed [BIT_COUNT-1:0] A2_WIRE [BIT_COUNT:1];
    logic signed [BIT_COUNT-1:0] A3_WIRE [BIT_COUNT:1];
    logic signed [BIT_COUNT-1:0] Q1_WIRE [BIT_COUNT:1];
    logic signed [BIT_COUNT-1:0] Q2_WIRE [BIT_COUNT:1];
    
    
    genvar i;
    generate 
        for(i = 1; i < BIT_COUNT; i++) begin
            
            assign A1_WIRE[i] = {A_REG_OUT[i][MSB-1:0], Q_REG_OUT[i][MSB]};
            assign Q1_WIRE[i] = {Q_REG_OUT[i][MSB-1:0], 1'b0};
            
            assign A2_WIRE[i] = A1_WIRE[i] - M_REG_OUT[i];
            assign Q2_WIRE[i] = {Q1_WIRE[i][MSB:1], ~A2_WIRE[i][MSB]};
            assign A3_WIRE[i] = A2_WIRE[i][MSB] ? A2_WIRE[i] + M_REG_OUT[i] : A2_WIRE[i];
            
            
            // A REG
            d_ff #(
                .WIDTH(BIT_COUNT)
            ) A_REG (
                .clk(clk),
                .reset(reset),
                .data_in(A3_WIRE[i]),
                .q_out(A_REG_OUT[i+1])
            );
            // Q REG
            d_ff #(
                .WIDTH(BIT_COUNT)
            ) Q_REG (
                .clk(clk),
                .reset(reset),
                .data_in(Q2_WIRE[i]),
                .q_out(Q_REG_OUT[i+1])
            );
            // M REG
            d_ff #(
                .WIDTH(BIT_COUNT)
            ) M_REG (
                .clk(clk),
                .reset(reset),
                .data_in(M_REG_OUT[i]),
                .q_out(M_REG_OUT[i+1])
            );
            // SIGN REG
            d_ff #(
                .WIDTH(1)
            ) SIGN_REG (
                .clk(clk),
                .reset(reset),
                .data_in(SIGN_REG_OUT[i]),
                .q_out(SIGN_REG_OUT[i+1])
            );
            // START REG
            d_ff #(
                .WIDTH(1)
            ) START_REG (
                .clk(clk),
                .reset(reset),
                .data_in(START_REG_OUT[i]),
                .q_out(START_REG_OUT[i+1])
            );
            // ZERO REG
            d_ff #(
                .WIDTH(1)
            ) ZERO_REG (
                .clk(clk),
                .reset(reset),
                .data_in(ZERO_REG_OUT[i]),
                .q_out(ZERO_REG_OUT[i+1])
            );
        end
    endgenerate

            // A REG
            d_ff #(
                .WIDTH(BIT_COUNT)
            ) A_REG_LAST (
                .clk(clk),
                .reset(reset),
                .data_in(A3_WIRE[BIT_COUNT-1]),
                .q_out(A_REG_OUT[BIT_COUNT])
            );
            // Q REG
            d_ff #(
                .WIDTH(BIT_COUNT)
            ) Q_REG_LAST (
                .clk(clk),
                .reset(reset),
                .data_in(Q2_WIRE[BIT_COUNT-1]),
                .q_out(Q_REG_OUT[BIT_COUNT])
            );
            // M REG
            d_ff #(
                .WIDTH(BIT_COUNT)
            ) M_REG_LAST (
                .clk(clk),
                .reset(reset),
                .data_in(M_REG_OUT[BIT_COUNT-1]),
                .q_out(M_REG_OUT[BIT_COUNT])
            );
            // SIGN REG
            d_ff #(
                .WIDTH(1)
            ) SIGN_REG_LAST (
                .clk(clk),
                .reset(reset),
                .data_in(SIGN_REG_OUT[BIT_COUNT-1]),
                .q_out(SIGN_REG_OUT[BIT_COUNT])
            );
            // START REG
            d_ff #(
                .WIDTH(1)
            ) START_REG_LAST (
                .clk(clk),
                .reset(reset),
                .data_in(START_REG_OUT[BIT_COUNT-1]),
                .q_out(START_REG_OUT[BIT_COUNT])
            );
            // ZERO REG
            d_ff #(
                .WIDTH(1)
            ) ZERO_REG_LAST (
                .clk(clk),
                .reset(reset),
                .data_in(ZERO_REG_OUT[BIT_COUNT-1]),
                .q_out(ZERO_REG_OUT[BIT_COUNT])
            );

        assign A1_WIRE[BIT_COUNT] = {A_REG_OUT[BIT_COUNT][MSB-1:0], Q_REG_OUT[BIT_COUNT][MSB]};
        assign Q1_WIRE[BIT_COUNT] = {Q_REG_OUT[BIT_COUNT][MSB-1:0], 1'b0};
        
        assign A2_WIRE[BIT_COUNT] = A1_WIRE[BIT_COUNT] - M_REG_OUT[BIT_COUNT];
        assign Q2_WIRE[BIT_COUNT] = {Q1_WIRE[BIT_COUNT][MSB:1], ~A2_WIRE[BIT_COUNT][MSB]};
        assign A3_WIRE[BIT_COUNT] = A2_WIRE[BIT_COUNT][MSB] ? 
                    A2_WIRE[BIT_COUNT] + M_REG_OUT[BIT_COUNT] : A2_WIRE[BIT_COUNT];
        
            
    always_comb begin
        if(START_REG_OUT[BIT_COUNT]) begin
            // negatifse
            if(SIGN_REG_OUT[BIT_COUNT]) begin
                // bolen 0 ise eksi sonsuz
                if(ZERO_REG_OUT[BIT_COUNT]) begin
                    quotient_out = MIN;
                end else begin
                // bolen 0 degilse 2's complement al
                    quotient_out = -Q2_WIRE[BIT_COUNT][WIDTH-1:0];
                end
            
            // pozitifse
            end else begin
                // bolen 0 ise arti sonsuz
                if(ZERO_REG_OUT[BIT_COUNT]) begin
                    quotient_out = MAX;
                end else begin
                // bolen 0 degil ise normal cikar
                    quotient_out = Q2_WIRE[BIT_COUNT][WIDTH-1:0];
                end
            end
        end
        valid_out = START_REG_OUT[BIT_COUNT];
    end
    
endmodule