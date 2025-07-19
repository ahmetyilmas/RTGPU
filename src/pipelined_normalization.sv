`timescale 1ns / 1ps
`include "Types.sv"
/*
 48 TAG_SIZE 16 Div cluster için
 Bu modül 12639 LUT, 11286 FF, 5.50 BRAM ve 3 DSP kullanıyor
*/
    // len = sqrt(x^2 + y^2 + z^2)
    // L'x = Lx / len
    // L'y = Ly / len
    // L'z = Lz / len
module pipelined_normalization #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter DIV_COUNT = 16,
    parameter TAG_SIZE = `TAG_SIZE
    )(
    input clk,
    input reset,
    input start,
    input RayDirection ray_in,
    output RayDirection normalized_ray_out, // normalized x,y,z directions
    output logic valid_out
    );
    
    logic mul_valid;
    
    // isin yonlerinin kareleri
    Vec3 RD_square;
    
    direction_square #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) dir_sqr (
    .clk(clk),
    .start(start),
    .RD_in(ray_in),
    .valid(mul_valid),
    .RDS_out(RD_square)
    );
    
    wire [WIDTH-1:0]sum;
    assign sum = RD_square.x + RD_square.y + RD_square.z;
    
    logic sqrt_valid;
    RayDirection_len RD_len;
    
    // BURADAYIM
    
    sqroot_tagged #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) sqrt_core (
    .clk(clk),
    .start(mul_valid),
    .reset(reset),
    .x_in(sum),
    .TD_in(RD_square),
    .valid_out(sqrt_valid),
    .TDL_out(RD_len)
    );
    
    logic sqrt_buffer_ready;
    logic sqrt_buffer_valid;
    logic read_in;
    TaggedDirection_len TDL_fifo_out;
    
    // Tag + Direction + len fifo
    tdl_dp_fifo #(
    .WIDTH(WIDTH),
    .DEPTH(32),
    .TAG_SIZE(TAG_SIZE)
    ) sqrt_buffer (
    .clk(clk),
    .reset(reset),
    .read(read_in),
    .write(sqrt_valid),
    .TDL_in(TDL_sqrt),
    .TDL_out(TDL_fifo_out),
    .ready(sqrt_buffer_ready),
    .overflow(),
    .valid_out(sqrt_buffer_valid)
    );
    
    TaggedDirection_len TDL_div_in;
    assign TDL_div_in = TDL_fifo_out;
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
    assign read_in = |div_req & sqrt_buffer_ready;
    
    logic fifo_overflow[DIV_COUNT-1:0];
    
    // div'lerin start portunun baglantisini yap
    genvar j;
    for(j = 0; j < DIV_COUNT; j++) begin
        assign div_gnt_start[j] = sqrt_buffer_valid & div_gnt[j] & ~fifo_overflow[j];
    end
    
    
    logic [DIV_COUNT-1:0]div_valid;
    TaggedNormalized normalized[DIV_COUNT-1:0];
    
    // XYZ divider'lari olustur
    genvar i;
    generate
        for(i = 0; i < DIV_COUNT; i++) begin
            div_cluster #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
            ) divXYZ(
            .clk(clk),
            .start(div_gnt_start[i]),
            .reset(reset),
            .TDL_in(TDL_fifo_out),
            .valid(div_valid[i]),
            .ready(div_req[i]),
            .normalized(normalized[i])
            );
        end
    endgenerate
    
    
    logic fifo_valid;
    TaggedNormalized tagged_fifo_out;
    // out-of-order cikan div sonuclarini sirayla cikarmak icin sorted fifo
    sorted_fifo #(
    .DEPTH(32),
    .TAG_SIZE(TAG_SIZE),
    .DIV_COUNT(DIV_COUNT)
    ) sorted_fifo (
    .clk(clk),
    .reset(reset),
    .div_valid_in(div_valid),
    .tagged_norm_in(normalized),
    .fifo_overflow_out(fifo_overflow),
    .tagged_norm_out(tagged_fifo_out),
    .valid_out(fifo_valid)
    );
    assign normal = tagged_fifo_out;
    assign valid_out = fifo_valid;
endmodule
