`timescale 1ns / 1ps
`include "Types.sv"

// normalizasyon icin birlestirilmis x,y,z kordinatlarini
// hesaplayacak divider blogu
module div_cluster #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS   // Q3.12
    )(
    
    input clk,
    input start,
    input reset,
    input TaggedDirection_len TDL_in,
    output logic valid,
    output logic ready,
    output TaggedNormalized normalized
    );
    
    localparam TAG_SIZE = `TAG_SIZE;
    
    
    logic valid_x, valid_y, valid_z;
    logic ready_x, ready_y, ready_z;
    logic valid_ff;
    
    wire [WIDTH-1:0]quotient_x;
    wire [WIDTH-1:0]quotient_y;
    wire [WIDTH-1:0]quotient_z;
    
    logic ready_ff;
    logic [TAG_SIZE:0]tag_ff;
    // Divider
    divider #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) divX (
    .clk(clk),
    .reset(reset),
    .start(start),
    .dividend(TDL_in.direction.x),
    .divisor(TDL_in.len),
    .valid(valid_x),
    .ready(ready_x),
    .quotient(quotient_x)
    );
    
    // Divider
    divider #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) divY (
    .clk(clk),
    .reset(reset),
    .start(start),
    .dividend(TDL_in.direction.y),
    .divisor(TDL_in.len),
    .valid(valid_y),
    .ready(ready_y),
    .quotient(quotient_y)
    );
    
    // Divider
    divider #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) divZ (
    .clk(clk),
    .reset(reset),
    .start(start),
    .dividend(TDL_in.direction.z),
    .divisor(TDL_in.len),
    .valid(valid_z),
    .ready(ready_z),
    .quotient(quotient_z)
    );
    
    assign valid_ff = valid_x & valid_y & valid_z;
    assign ready = ready_x & ready_y & ready_z;
    //assign normalized.tag = TDL_in.tag;
    
    always_ff @(posedge clk) begin
        if(start) begin
            tag_ff <= TDL_in.tag;
        end
        if(valid_ff) begin
            normalized.direction.x <= quotient_x;
            normalized.direction.y <= quotient_y;
            normalized.direction.z <= quotient_z;
            normalized.tag <= tag_ff;
            valid <= 1;
        end else begin
            valid<= 0;
        end 
    end
endmodule
