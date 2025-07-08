`timescale 1ns / 1ps
`include "Types.sv"

module divider #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS   // Q3.12
)(
    input clk,
    input start,
    input reset,
    input wire signed[WIDTH-1:0]dividend,
    input wire signed[WIDTH-1:0]divisor,
    output logic valid,
    output logic ready,
    output logic signed[WIDTH-1:0]quotient
);
    typedef enum logic[1:0] {
        DIV_IDLE,
        DIV_PREP,
        DIV_RUNNING
    }fsm_state;
    
    
    logic signed[WIDTH+Q_BITS-1:0]dividend_reg;
    logic signed[WIDTH-1:0]divisor_reg;
    logic       [WIDTH+Q_BITS-1:0]divisor_shifted;
    logic signed[WIDTH+Q_BITS-1:0]quotient_reg;
    logic       [1:0]current_state, next_state;
    logic divisor_neg;
    logic dividend_neg;
    
    assign divisor_neg = divisor[WIDTH-1] == 1;
    assign dividend_neg = dividend[WIDTH-1] == 1;
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            dividend_reg <= 0;
            divisor_reg <= 0;
            divisor_shifted <= 0;
            quotient_reg <= 0;
            valid <= 0;
            ready <= 1;
            current_state <= DIV_IDLE;
            next_state <= DIV_PREP;
        end else if(start && current_state == DIV_IDLE) begin
        // start sinyali geldiyse ve islem yapilmiyorsa PREP durumuna gec ve
        // sonraki durumu islemi yapmak icin RUNNING olarak ayarla
            valid <= 0;
            dividend_reg[WIDTH+Q_BITS-1:Q_BITS] <= dividend_neg ? -dividend : dividend;
            divisor_reg <= divisor_neg ? -divisor : divisor;
            divisor_shifted[WIDTH+Q_BITS-1:Q_BITS] <= divisor_neg ? -divisor : divisor;
            
            current_state <= next_state;
            next_state <= DIV_RUNNING;
            ready <= 0;
        end else if(current_state == DIV_PREP) begin
        // divisor'in ilk bitini 1 yapacak sekilde kaydirmak icin hangi indexin
        // 1 oldugunu soldan baslayarak bul ve MSB = 1 olacak sekilde kaydir.
            if(divisor_shifted[WIDTH+Q_BITS-1] != 1'b1) begin
                divisor_shifted <= divisor_shifted << 1;
            end else begin
                current_state <= next_state;
                next_state <= DIV_RUNNING;
            end
            
        // eger RUNNING durumundaysa islemi yap
        end else if(current_state == DIV_RUNNING) begin
            if(divisor_shifted < dividend_reg || divisor_shifted == dividend_reg) begin
                quotient_reg <= quotient_reg << 1 | 1'b1; ;
                dividend_reg <= dividend_reg - divisor_shifted;
                // eger yapilan son islemde kullanilan bolen kaydirilmadan onceki bolene esitse
                // islem bitmis demektir.
                if(divisor_shifted[WIDTH-1:0] != divisor_reg) begin
                    divisor_shifted <= divisor_shifted >> 1;
                end else begin
                    current_state <= DIV_IDLE;
                    next_state <= DIV_PREP;
                    valid <= 1;
                    ready <= 1;
                end
            end else begin
                quotient_reg <= quotient_reg << 1;
                if(divisor_shifted[WIDTH-1:0] != divisor_reg) begin
                    divisor_shifted <= divisor_shifted >> 1;
                end else begin
                    current_state <= DIV_IDLE;
                    next_state <= DIV_PREP;
                    valid <= 1;
                    ready <= 1;
                end
            end
            
        end else if (current_state == DIV_IDLE) begin
            valid <= 0;
        end
    end
    
    assign quotient = (dividend_neg ^ divisor_neg) ? -quotient_reg[WIDTH-1:0] : quotient_reg[WIDTH-1:0];
    
endmodule
