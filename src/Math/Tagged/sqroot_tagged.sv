`timescale 1ns / 1ps
`include "Types.sv"


module sqroot_tagged #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter TAG_SIZE = 64
    )(
    input clk,
    input start,
    input reset,
    input logic [WIDTH-1:0]x_in,
    input TaggedDirection TD_in,        // TaggedDirection Tag ve RayDirection icerir
    output logic valid_out,
    output TaggedDirection_len TDL_out  // TaggedDirection_len; Tag, RayDirection ve len icerir
    );
    
    logic sqrt_valid;
    logic valid_ff;
    logic fifo_ready;
    logic fifo_valid;
    
    logic [WIDTH+Q_BITS-1:0]x_in_ext;
    assign x_in_ext = {x_in,{Q_BITS{1'b0}}};
    
    logic signed [`WIDTH-1:0]len;
    
    TaggedDirection TD_ff;
    TaggedDirection_len TDL_ff;
    
    tagged_dir_fifo #(
    .TAG_SIZE(TAG_SIZE),
    .DEPTH(32)
    ) tag_buffer (
    .clk(clk),
    .reset(reset),
    .read(sqrt_valid),
    .write(start),
    .dir_in(TD_in),
    .dir_out(TD_ff),
    .ready(fifo_ready),
    .overflow(),
    .valid(fifo_valid)
    );
    
    cordic_0 sqrt_core (
            .aclk(clk),
            .s_axis_cartesian_tdata(x_in_ext),
            .s_axis_cartesian_tvalid(start),
            .m_axis_dout_tdata(len),
            .m_axis_dout_tvalid(sqrt_valid)
        );
    
    always_ff @(posedge clk) begin
        //  fifo ile senkron calismasi icin FF'e at
        /*
        if(sqrt_valid) begin
            valid_ff <= sqrt_valid;
        end*/
        if(reset) begin
            TDL_ff <= 0;
            valid_out <= 0;
        end else begin
            if(sqrt_valid) begin
                //TDL_ff.direction.x <= TD_ff.direction.x;
                //TDL_ff.direction.y <= TD_ff.direction.y;
                //TDL_ff.direction.z <= TD_ff.direction.z;
                //TDL_ff.tag <= TD_ff.tag;
                //TDL_ff.len <= {1'b0, len[WIDTH-2:0]};   // len 15 bit o yuzden ilk bitine 0 ekliyoruz
                TDL_ff <= '{
                direction : TD_ff.direction,
                tag : TD_ff.tag,
                len : len};
                valid_out <= 1;
            end else begin
                valid_out <= 0;
            end
        end
    end
    // {1'b0, len[WIDTH-2:0]}
    assign TDL_out = TDL_ff;
    
endmodule
