`timescale 1ns / 1ps
`include "Types.sv"

// 1/dir icin birlestirilmis x,y,z kordinatlarini
// hesaplayacak divider blogu
module inv_div_cluster #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS   // Q3.12
    )(
    
    input clk,
    input start,
    input reset,
    input TaggedDirection TD_in,
    output logic valid,
    output logic ready,
    output TaggedDirection ITD_out
    );
    
    localparam TAG_SIZE = `TAG_SIZE;
    
    
    logic valid_x, valid_y, valid_z;
    logic ready_x, ready_y, ready_z;
    logic valid_ff;
    TaggedDirection inv_dir_ff;
    logic ready_ff;
    
    // Divider
    divider #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) divX (
    .clk(clk),
    .reset(reset),
    .start(start),
    .dividend({4'h1, {(WIDTH-4){1'b0}}}), // 16'h0001_0000_0000_0000
    .divisor(TD_in.direction.x),
    .valid(valid_x),
    .ready(ready_x),
    .quotient(inv_dir_ff.direction.x)
    );
    
    // Divider
    divider #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) divY (
    .clk(clk),
    .reset(reset),
    .start(start),
    .dividend({4'h1, {(WIDTH-4){1'b0}}}),
    .divisor(TD_in.direction.y),
    .valid(valid_y),
    .ready(ready_y),
    .quotient(inv_dir_ff.direction.y)
    );
    
    // Divider
    divider #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) divZ (
    .clk(clk),
    .reset(reset),
    .start(start),
    .dividend({4'h1, {(WIDTH-4){1'b0}}}),
    .divisor(TD_in.direction.z),
    .valid(valid_z),
    .ready(ready_z),
    .quotient(inv_dir_ff.direction.z)
    );
    
    assign valid_ff = valid_x & valid_y & valid_z;
    assign ready = ready_x & ready_y & ready_z;
    //assign normalized.tag = TDL_in.tag;
    
    always_ff @(posedge clk) begin
        if(start) begin
            inv_dir_ff.tag <= TD_in.tag;
        end
        if(valid_ff) begin
            ITD_out <= inv_dir_ff;
            valid <= 1;
        end else if((valid_x & ready_y & ready_z) || (valid_y & ready_x & ready_z) || (valid_z & ready_x & ready_y) )begin
            ITD_out <= inv_dir_ff;
            valid <= 1;
        end else begin
            valid<= 0;
        end 
    end
endmodule
