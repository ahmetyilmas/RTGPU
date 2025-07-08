`timescale 1ns / 1ps
`include "Types.sv"

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
    input RayDirection dir,
    output RayDirection normal, // normalized x,y,z directions
    output logic valid_out
    );
    
    logic [TAG_SIZE-1:0] tag_used; // 64 bit: Her tag için 1-bit
    logic current_tag;
    
    TaggedDirection taggedDir;
    
    
    // Tag atanirken:
    always_ff @(posedge clk) begin
        if (start) begin
            for (int i = 0; i < TAG_SIZE; i++) begin
                if (!tag_used[i]) begin
                    current_tag <= i;
                    tag_used[i] <= 1;
                    taggedDir.tag <= tag_used;
                    taggedDir.direction <= dir;
                    break;
                end
            end
        end
    end
    
    // giris vektoru (0,0,0) ise atla
    wire skip;
    assign skip = ~|(dir.x | dir.y | dir.z);
    logic mul_start;
    assign mul_start = start & !skip;
    
    logic mul_valid;
    
    TaggedDirection_pow tdp;
    
    tagged_mul #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS),
    .TAG_SIZE(TAG_SIZE)
    ) mul (
    .clk(clk),
    .start(mul_start),
    .dir_in(taggedDir),
    .valid(mul_valid),
    .TDP_out(tdp)           // TaggedDirection + power(x,y,z)
    );
    
    
    
    wire [WIDTH-1:0]sum;
    assign sum = tdp.pow.x + tdp.pow.y + tdp.pow.z;
    
    TaggedDirection TD_sqrt;
    assign TD_sqrt.direction = tdp.direction;
    assign TD_sqrt.tag = tdp.tag;
    
    logic sqrt_valid;
    TaggedDirection_len TDL_sqrt;
    
    
    sqroot_tagged #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) sqrt_core (
    .clk(clk),
    .start(mul_valid),
    .reset(reset),
    .x_in(sum),
    .TD_in(TD_sqrt),
    .valid_out(sqrt_valid),
    .TDL_out(TDL_sqrt)
    );
    
    logic sqrt_buffer_ready;
    logic sqrt_buffer_valid;
    logic read_in;
    logic [WIDTH-1:0] fifo_out;
    
    fifo #(
    .WIDTH(WIDTH),
    .DEPTH(32)
    ) sqrt_buffer (
    .clk(clk),
    .reset(reset),
    .read(read_in),
    .write(sqrt_valid),
    .data_in(len),
    .data_out(fifo_out),
    .ready(sqrt_buffer_ready),
    .overflow(),
    .valid(sqrt_buffer_valid)
    );
    
    logic dir_buffer_ready;
    logic dir_buffer_valid;
    
    RayDirection dir_fifo_out;
    
    dir_fifo #(
    .WIDTH(WIDTH),
    .DEPTH(32)
    ) direction_buffer (
    .clk(clk),
    .reset(reset),
    .read(read_in),
    .write(mul_valid_all),
    .data_in(dir),
    .data_out(dir_fifo_out),
    .ready(dir_buffer_ready),
    .overflow(),
    .valid(dir_buffer_valid)
    );
    
    
    
    wire [DIV_COUNT-1:0]div_req;    // bosta bulunan divider portlari
    wire [DIV_COUNT-1:0]div_gnt;    // start sinyali verilen divider portlari
    
    logic [DIV_COUNT-1:0]div_valid;
    RayDirection normalized[DIV_COUNT-1:0];
    
    wire [DIV_COUNT-1:0]div_gnt_start;
    
    
    round_robin_arbiter #(
    .NUM_PORTS(WIDTH)
    )div_arbiter (
    .clk(clk),
    .reset(reset),
    .req_i(div_req),
    .gnt_o(div_gnt)
    );

    // buffer ready ise ve istekte bulunan divider var ise fifo'dan oku
    assign read_in = |div_req & sqrt_buffer_ready & dir_buffer_ready;
    
    // div'lerin start portunun baglantisini yap
    genvar j;
    for(j = 0; j < DIV_COUNT; j++) begin
        assign div_gnt_start[j] = sqrt_buffer_valid & dir_buffer_valid & div_gnt[j];
    end
    
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
            .direction(dir_fifo_out),
            .len(fifo_out),
            .valid(div_valid[i]),
            .ready(div_req[i]),
            .normalized(normalized[i])
            );
        end
    endgenerate

    //assign normal = normalized[];
    assign valid_out = |div_valid;
endmodule
