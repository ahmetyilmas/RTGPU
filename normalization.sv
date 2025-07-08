`timescale 1ns / 1ps
`include "Types.sv"


    // len = sqrt(x^2 + y^2 + z^2)
    // L'x = Lx / len
    // L'y = Ly / len
    // L'z = Lz / len

    // OLD
module normalization #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS
)(
    input clk,
    input reset,
    input start,
    input RayDirection dir,
    output RayDirection normal, // normalized x,y,z directions
    output logic valid_out,
    output state norm_state
);
    
    // giris vektoru (0,0,0) ise atla
    wire skip;
    assign skip = ~|(dir.x | dir.y | dir.z);
    //logic start_ff;
    logic mul_start;
    assign mul_start = start & !skip;
    
    wire  [WIDTH-1:0]pow_x;
    wire  [WIDTH-1:0]pow_y;
    wire  [WIDTH-1:0]pow_z;
    wire mul_x_valid;
    wire mul_y_valid;
    wire mul_z_valid;
    logic mul_valid_all;
    
    state mul_state_x,mul_state_y,mul_state_z;
    
    state sqrt_state;
    state div_state_x,div_state_y,div_state_z;
    state current_state;
    state next_state;
    
    multiplication #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) mulX(
    .start(mul_start),
    .reset(reset),
    .clk(clk),
    .sqrt_state(sqrt_state),
    .a(dir.x),
    .b(dir.x),
    .next_start(mul_x_valid),
    .state_out(mul_state_x),
    .result(pow_x)
    );
    
    multiplication #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    ) mulY(
    .start(mul_start),
    .reset(reset),
    .clk(clk),
    .sqrt_state(sqrt_state),
    .a(dir.y),
    .b(dir.y),
    .next_start(mul_y_valid),
    .state_out(mul_state_y),
    .result(pow_y)
    );
        
    multiplication #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) mulZ(
    .start(mul_start),
    .reset(reset),
    .clk(clk),
    .sqrt_state(sqrt_state),
    .a(dir.z),
    .b(dir.z),
    .next_start(mul_z_valid),
    .state_out(mul_state_z),
    .result(pow_z)
    );

    wire [WIDTH-1:0]sum;
    assign sum = pow_x + pow_y + pow_z;
    assign mul_valid_all = mul_x_valid & mul_y_valid & mul_z_valid;
    
    
    wire [WIDTH-1:0]len;
    wire div_start;
    state div_state;
    
    
    sqroot #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS)
    )sqroot(
    .clk(clk),
    .reset(reset),
    .start(mul_valid_all),
    .x_in(sum),
    .div_state(div_state),
    .next_start(div_start),
    .state_out(sqrt_state),
    .result(len)
    );
        
    RayDirection normalized;   // normalized light directions
    logic valid_x,valid_y,valid_z;
    
    
    float_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    )dividerX(
        .clk(clk),
        .reset(reset),
        .start(div_start),
        .dividend(dir.x),
        .divisor(len),
        .quotient(normalized.x),
        .div_state(div_state_x),
        .valid(valid_x)
    );
    
    float_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    )dividerY(
        .clk(clk),
        .reset(reset),
        .start(div_start),
        .dividend(dir.y),
        .divisor(len),
        .quotient(normalized.y),
        .div_state(div_state_y),
        .valid(valid_y)
    );
    
    float_divider #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    )dividerZ(
        .clk(clk),
        .reset(reset),
        .start(div_start),
        .dividend(dir.z),
        .divisor(len),
        .quotient(normalized.z),
        .div_state(div_state_z),
        .valid(valid_z)
    );
    
    
    
    wire valid_all;
    assign valid_all = valid_x & valid_y & valid_z;
    logic valid_ff;
    assign div_state = (div_state_x == IDLE & div_state_y == IDLE & div_state_z == IDLE) ? IDLE : BUSY;
   always_ff @(posedge clk or posedge reset or posedge skip) begin
        if (reset | skip) begin
            normal.x <= 0;
            normal.y <= 0;
            normal.z <= 0;
            valid_out <= 0;
            //valid_ff <= 0;
        end else if(valid_all) begin
            normal.x <= normalized.x;
            normal.y <= normalized.y;
            normal.z <= normalized.z;
            valid_out <= valid_all;
            //valid_ff <= 1;
        end else begin
            valid_out <= 0;
        end
    end
    
    always_comb begin
    
    end
    
    assign norm_state = (mul_state_x == IDLE) ? (sqrt_state == BUSY | sqrt_state == WAITING) 
                        ? ACCEPTING : (div_state_x == BUSY | div_state_x == WAITING)
                         ? ACCEPTING : IDLE: (mul_state_x == WAITING | mul_state_x == BUSY) ? BUSY : BUSY;
    /*
    always_ff @(posedge clk or posedge reset or posedge skip) begin
        if (reset | skip) begin
            normal.x <= 0;
            normal.y <= 0;
            normal.z <= 0;
            current_state <= IDLE;
            next_state <= BUSY;
            valid_ff <= 0;
        end else if(current_state <= IDLE & start) begin
            current_state <= next_state;
            next_state <= IDLE;
            valid_ff <= 0;
            start_ff <= start;
        end else if (current_state <= BUSY) begin
            if(start) begin
                start_ff <= 1;
            end else if(!valid_ff) begin
                start_ff <= 0;
            end
        end  else if(current_state == BUSY & valid_all) begin
            normal.x <= normalized.x;
            normal.y <= normalized.y;
            normal.z <= normalized.z;
            valid_ff <= valid_all;
            current_state <= next_state;
            next_state <= BUSY;
        end
    end*/
    //assign norm_state = current_state;
    //assign valid = valid_all;
endmodule
