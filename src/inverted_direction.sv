`timescale 1ns / 1ps
`include "Types.sv"

// 16 DIV cluster, 48 tag size ile bu modul
// 11706 LUT 13418 FF 0 DSP kullanıyor
module inverted_direction #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter TAG_SIZE = `TAG_SIZE,
    parameter DIV_COUNT = 16
    )
    (
    input clk,
    input start,
    input reset,
    input TaggedDirection direction_in,
    output logic valid_out,
    output TaggedDirection inv_dir_out
    );
    
    TaggedDirection tagged_direction;
    assign tagged_direction = direction_in;
    
    TaggedDirection TD_fifo_out;
    logic TD_buffer_ready;
    logic TD_buffer_valid;
    logic read_in;
    
    
    
    TD_fifo #(
    .DEPTH(24),
    .TAG_SIZE(TAG_SIZE)
    ) TD_buffer (
    .clk(clk),
    .reset(reset),
    .read(read_in),
    .write(start),
    .TD_in(tagged_direction),
    .TD_out(TD_fifo_out),
    .ready(TD_buffer_ready),
    .overflow(),
    .valid(TD_buffer_valid)
    );
    
    wire [DIV_COUNT-1:0]div_req;        // bosta bulunan divider portlari
    wire [DIV_COUNT-1:0]div_gnt;        // izin verilen divider portlari
    wire [DIV_COUNT-1:0]div_gnt_start;  // start sinyali verilen divider portlari
    
    
    round_robin_arbiter #(
    .NUM_PORTS(DIV_COUNT)
    )div_arbiter (
    .clk(clk),
    .reset(reset),
    .req_i(div_req),
    .gnt_o(div_gnt)
    );
    // buffer ready ise ve istekte bulunan divider var ise fifo'dan oku
    assign read_in = |div_req & TD_buffer_ready;
    
    logic fifo_overflow[DIV_COUNT-1:0];
    
    // div'lerin start portunun baglantisini yap
    genvar j;
        for(j = 0; j < DIV_COUNT; j++) begin
            assign div_gnt_start[j] = TD_buffer_valid & div_gnt[j] & ~fifo_overflow[j];
    end
    
    logic [DIV_COUNT-1:0]div_valid;
    TaggedDirection inverted[DIV_COUNT-1:0];
    
    
    // XYZ divider'lari olustur
    genvar i;
    generate
        for(i = 0; i < DIV_COUNT; i++) begin
            inv_div_cluster #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
            ) divXYZ(
            .clk(clk),
            .start(div_gnt_start[i]),
            .reset(reset),
            .TD_in(TD_fifo_out),
            .valid(div_valid[i]),
            .ready(div_req[i]),
            .ITD_out(inverted[i])
            );
        end
    endgenerate
    
    logic fifo_valid;
    TaggedDirection tagged_fifo_out;
    // out-of-order cikan div sonuclarini sirayla cikarmak icin sorted fifo
    sorted_fifo #(
    .DEPTH(32),
    .TAG_SIZE(TAG_SIZE),
    .DIV_COUNT(DIV_COUNT)
    ) sorted_fifo (
    .clk(clk),
    .reset(reset),
    .div_valid_in(div_valid),
    .tagged_norm_in(inverted),
    .fifo_overflow_out(fifo_overflow),
    .tagged_norm_out(tagged_fifo_out),
    .valid_out(fifo_valid)
    );
    
    assign inv_dir_out = tagged_fifo_out;
    assign valid_out = fifo_valid;
endmodule
