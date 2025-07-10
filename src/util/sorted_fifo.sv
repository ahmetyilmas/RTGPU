`timescale 1ns / 1ps
`include "Types.sv"

// Tag + RayDirection + len structunu depolayan fifo
module sorted_fifo#(
    parameter DEPTH = 32,
    parameter TAG_SIZE = `TAG_SIZE,
    parameter DIV_COUNT = 16
    )(
    input clk,
    input reset,
    input logic [DIV_COUNT-1:0]div_valid_in,
    input TaggedNormalized tagged_norm_in [DIV_COUNT-1:0],
    output logic fifo_overflow_out[DIV_COUNT-1:0],
    output TaggedNormalized tagged_norm_out,
    output logic valid_out
    );
    
    logic write_fifo[DIV_COUNT-1:0];
    logic gnt_fifo[DIV_COUNT-1:0];
    
    TaggedNormalized fifo_data_in[DIV_COUNT-1:0];
    TaggedNormalized fifo_data_out[DIV_COUNT-1:0];
    
    generate
      for (genvar i = 0; i < DIV_COUNT; i++) begin
        assign write_fifo[i] = div_valid_in[i];
        assign fifo_data_in[i] = tagged_norm_in[i];
      end
    endgenerate
    
   /*
    round_robin_arbiter #(
    .NUM_PORTS(DIV_COUNT)
    ) div_select (
    .clk(clk),
    .reset(reset),
    .req_i(write_fifo),
    .gnt_o(gnt_fifo)
    );
    */
    
    logic fifo_ready[DIV_COUNT-1:0];
    logic fifo_valid[DIV_COUNT-1:0];
    logic [TAG_SIZE-1:0]fifo_tag[DIV_COUNT-1:0];
    logic fifo_read[DIV_COUNT-1:0];
    logic fifo_overflow[DIV_COUNT-1:0];     // fifo dolduysa divider yeni veriyi gondermemeli
    
    genvar j;
    generate
        for(j = 0; j < DIV_COUNT; j++) begin
            // her divider icin 2 derinlikte fifo
            tagged_norm_fifo #(
            .DEPTH(2)
            ) norm_fifo (
            .clk(clk),
            .reset(reset),
            .read(fifo_read[j]),
            .write(write_fifo[j]),
            .tagged_normalized_in(fifo_data_in[j]),
            .tagged_normalized_out(fifo_data_out[j]),
            .ready(fifo_ready[j]),
            .overflow(fifo_overflow[j]),
            .valid(fifo_valid[j]),
            .tag_out(fifo_tag[j])
            );
        end
    endgenerate
    
    logic [TAG_SIZE-1:0]expected_tag;
    logic [TAG_SIZE-1:0]next_tag;
    logic [DIV_COUNT-1:0]control;
    logic HALT;
    logic PREV_HALT;
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            expected_tag <= {TAG_SIZE{1'b0}};     // 64'h0000_0000_0000_0000
            next_tag <= {{TAG_SIZE-1{1'b0}}, 1'b1};         // 64'h0000_0000_0000_0001
            valid_out <= 0;
        end else begin
            valid_out <= 0;
            for(int index = 0; index < DIV_COUNT; index++) begin
                // eger fifo_read expected_tag kismina koyulursa 1 cycle gecikilecek 
                // ve yanlis veri okunacak. o yuzden kontrol isini next_tag kismindan
                // yapiyoruz. ilk seferde ilk if calismayacak.calismasin, napalim?
                
                if(fifo_data_out[index].tag == expected_tag) begin
                    fifo_read[index] <= 0;
                    tagged_norm_out <= fifo_data_out[index];
                    valid_out <= 1;
                    
                    expected_tag <= HALT ? expected_tag : next_tag;
                    next_tag <= (next_tag == {{TAG_SIZE{1'b1}}}) ? // 64'h1000_0000_0000_0000 ise basa donuyoruz
                            {{TAG_SIZE-1{1'b0}}, 1'b1} : HALT ? next_tag : (next_tag << 1)|1 ; // tag one-hot sinyal olduğundan sola kaydir
                end
                 if(PREV_HALT) begin
                    valid_out <= 0;
                 end
                 if(PREV_HALT && !HALT) begin
                    expected_tag <= next_tag;;
                    next_tag <= (next_tag == {{TAG_SIZE{1'b1}}}) ? // 64'h1000_0000_0000_0000 ise basa donuyoruz
                                        {{TAG_SIZE-1{1'b0}}, 1'b1} : (next_tag << 1)|1 ;
                 end
                // eger next_tag fifoya geldiyse fifo_read 1 yap
                if(fifo_tag[index] == next_tag) begin
                    // ilk seferde ilk if calismadigindan expected_tag ve next_tag'i guncelle
                    if(expected_tag == {TAG_SIZE{1'b0}}) begin
                        expected_tag <= next_tag;
                        next_tag <= (next_tag << 1)|1;
                    end
                    fifo_read[index] <= HALT ? 0 : 1;
                end else begin
                    fifo_read[index] <= 0;
                end
            end
            PREV_HALT <= HALT;
        end
    end
    
    always_comb begin
        for(int i = 0; i < DIV_COUNT; i++) begin
            //control[i] = fifo_read[i];
            if(fifo_tag[i] == next_tag) begin
                control[i] = 1; 
            end else begin
                control[i] = 0;
            end
        end
        if(expected_tag != {TAG_SIZE{1'b0}} && ~(|control)) begin
            HALT = 1;
        end else begin
            HALT = 0;
        end
    end
    
    assign fifo_overflow_out = fifo_overflow;
endmodule