`timescale 1ns / 1ps
`include "Types.sv"

module fifo#(
    parameter WIDTH = `WIDTH,
    parameter DEPTH = 32
    )(
    input clk,
    input reset,
    input read,
    input write,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output logic ready,
    output logic overflow,
    output logic valid
    );
    
    
    logic [WIDTH-1:0]fifo_buffer[DEPTH-1:0];
    logic [$clog2(DEPTH)-1:0] write_pointer;
    logic [$clog2(DEPTH)-1:0] read_pointer;
    logic [$clog2(DEPTH+1)-1:0] fifo_count;
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            write_pointer <= 0;
            read_pointer <= 0;
            fifo_count <= 0;
            overflow <= 0;
            valid <= 0;
        end else begin
            overflow <= 0;
            valid <= 0;
            if(write && !read && fifo_count < DEPTH) begin
                fifo_buffer[write_pointer] <= data_in;       //datayı yaz
                write_pointer <= (write_pointer + 1) % DEPTH;//pointer++
                fifo_count <= fifo_count + 1;                // count++
            end else if(write && fifo_count == DEPTH) begin
                overflow <= 1;
            end 
            if(read && !write && fifo_count > 0) begin
                data_out <= fifo_buffer[read_pointer];      // datayi oku
                read_pointer <= (read_pointer + 1) % DEPTH; // pointer++
                fifo_count <= fifo_count - 1;               // count--
                valid <= 1;             
            end
            
            if(read && write && fifo_count < DEPTH && fifo_count > 0) begin
                data_out <= fifo_buffer[read_pointer];
                fifo_buffer[write_pointer] <= data_in;
                read_pointer <= (read_pointer + 1) % DEPTH;
                write_pointer <= (write_pointer + 1) % DEPTH;
                valid <= 1; 
                
            end
            
        end
    end
    
    assign ready = (fifo_count > 0);
endmodule
