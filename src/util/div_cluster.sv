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
    input RayDirection direction,
    input wire signed[WIDTH-1:0]len,
    output logic valid,
    output logic ready,
    output RayDirection normalized
    );
    
    
    logic valid_x, valid_y, valid_z;
    logic ready_x, ready_y, ready_z;
    
    // Divider
    divider #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) divX (
    .clk(clk),
    .reset(reset),
    .start(start),
    .dividend(direction.x),
    .divisor(len),
    .valid(valid_x),
    .ready(ready_x),
    .quotient(normalized.x)
    );
    
    // Divider
    divider #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) divY (
    .clk(clk),
    .reset(reset),
    .start(start),
    .dividend(direction.y),
    .divisor(len),
    .valid(valid_y),
    .ready(ready_y),
    .quotient(normalized.y)
    );
    
    // Divider
    divider #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) divZ (
    .clk(clk),
    .reset(reset),
    .start(start),
    .dividend(direction.z),
    .divisor(len),
    .valid(valid_z),
    .ready(ready_z),
    .quotient(normalized.z)
    );
    
    assign valid = valid_x & valid_y & valid_z;
    assign ready = ready_x & ready_y & ready_z;
    
endmodule
