`timescale 1ns / 1ps
`include "Types.sv"

    // ESKI FSM MANTIGIYLA YAPILMISTI
module inverted_direction #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter MAX = `MAX_16,
    parameter MIN = `MIN_16
    )
    (
    input clk,
    input start,
    input reset,
    input RayDirection norm_dir,
    output state state_out,
    output logic valid_out,
    output InvertedRayDirection inv_dir
    );
    
    logic valid_x, valid_y, valid_z;
    state current_state_x;
    state current_state_y;
    state current_state_z;
    state current_state;
    
    wire InvertedRayDirection inv;
    
    
    // giris vektoru (0,0,0) ise atla
    wire skip;
    assign skip = ~|(norm_dir.x | norm_dir.y | norm_dir.z);
    
    wire skip_x;
    wire skip_y;
    wire skip_z;
    assign skip_x = ~|(norm_dir.x);
    assign skip_y = ~|(norm_dir.y);
    assign skip_z = ~|(norm_dir.z);
    
    wire start_real_x;
    wire start_real_y;
    wire start_real_z;
    assign start_real_x = start & !skip_x;
    assign start_real_y = start & !skip_y;
    assign start_real_z = start & !skip_z;
    
    wire valid_skip_x;
    wire valid_skip_y;
    wire valid_skip_z;
    assign valid_skip_x = skip_x;
    assign valid_skip_y = skip_y;
    assign valid_skip_z = skip_z;
    
    //wire start_real;
    //assign start_real = start & !skip;
    state div_state_x,div_state_y,div_state_z;
    
    
    float_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    )divX(
        .clk(clk),
        .reset(reset),
        .start(start_real_x),
        .dividend($signed({4'h1,{WIDTH-4{1'b0}}})),
        .divisor(norm_dir.x),
        .quotient(inv.x),
        .div_state(div_state_x),
        .valid(valid_x)
    );
    
    float_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    )divY(
        .clk(clk),
        .start(start_real_x),
        .reset(reset),
        .dividend($signed({4'h1,{WIDTH-4{1'b0}}})),
        .divisor(norm_dir.y),
        .div_state(div_state_y),
        .quotient(inv.y),
        .valid(valid_y)
    );
        
    float_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    )divZ(
        .clk(clk),
        .start(start_real_z),
        .reset(reset),
        .dividend($signed({4'h1,{WIDTH-4{1'b0}}})),
        .divisor(norm_dir.z),
        .div_state(div_state_z),
        .quotient(inv.z),
        .valid(valid_z)
        );
        
    logic valid_all;
    assign valid_all = (valid_x | valid_skip_x) & (valid_y | valid_skip_y) & (valid_z  | valid_skip_z);
    
    assign current_state_x = (div_state_x == BUSY | div_state_x == WAITING) ? BUSY : IDLE;
    assign current_state_y = (div_state_y == BUSY | div_state_y == WAITING) ? BUSY : IDLE;
    assign current_state_z = (div_state_z == BUSY | div_state_z == WAITING) ? BUSY : IDLE;
    assign current_state =  (current_state_x == BUSY | current_state_y == BUSY | current_state_z == BUSY) ? BUSY : IDLE;
    
    always_ff @(posedge clk or posedge reset or posedge skip) begin
        if (reset | skip) begin
            inv_dir.x <= 0;
            inv_dir.y <= 0;
            inv_dir.z <= 0;
            state_out <= IDLE;
        end else if(valid_all) begin
            if(valid_skip_x) begin
                inv_dir.x <= MAX;
            end else begin
                inv_dir.x <= inv.x;
            end
            if(valid_skip_y) begin
                inv_dir.y <= MAX;
            end else begin
                inv_dir.y <= inv.y;
            end
            if(valid_skip_z) begin
                inv_dir.z <= MAX;
            end else begin
                inv_dir.z <= inv.z;
            end
            
            valid_out <= valid_all;
        end else begin
            state_out <= current_state;
        end
    end
endmodule
