    `timescale 1ns / 1ps
    `include "Types.sv"

    /*
    48 TAG_SIZE, 16 WIDTH, 22 Div cluster için
    ------------------------------------------
    Normalizasyon 15944 LUT, 8711 FF, 4.50 BRAM ve 3 DSP, 100 IO kullanıyor
    RayGenerator  22127 LUT, 11917 FF, 5.00 BRAM, 15 DSP, 244 IO kullanıyor
    */


    module RayGenerator #(
        parameter WIDTH = `WIDTH,
        parameter Q_BITS = `Q_BITS,
        parameter NORM_DIV_COUNT = `NORM_DIV_COUNT,
        parameter TAG_SIZE = `TAG_SIZE,
        parameter tan_fov = `tan_fov_half_16,
        parameter PIXEL_WIDTH = `PIXEL_WIDTH,
        parameter PIXEL_HEIGHT = `PIXEL_HEIGHT
        )(
        input  logic clk,
        input  logic reset,
        input  logic start,
        input  Camera cam, // origin, forward, up, fov ve aspect ratio degerleri
        output Ray ray_out,
        output logic valid_out
        );
        

        logic [PIXEL_WIDTH-1:0] pixel_x; //  0-639, 640
        logic [PIXEL_HEIGHT-1:0] pixel_y; // 0-479 480
        logic pixel_valid;

        always_ff @(posedge clk) begin
            if(reset) begin
                pixel_x <= {PIXEL_WIDTH{1'b1}};
                pixel_y <= 0;
                pixel_valid <= 0;
            end else if(start) begin
                if (pixel_x == 639) begin
                    pixel_x <= 0;
                    if (pixel_y == 479)
                        pixel_y <= 0;
                    else
                        pixel_y <= pixel_y + 1;
                pixel_valid <= 1;
                end else begin
                    pixel_x <= pixel_x + 1;
                    pixel_valid <= 1;
                end
            end
        end


        logic signed [WIDTH-1:0] u;
        logic signed [WIDTH-1:0] v;
        
        logic [WIDTH-1:0] u_lut [0:639];
        logic [WIDTH-1:0] v_lut [0:479];
        logic [WIDTH-1:0] u_ff;
        logic [WIDTH-1:0] v_ff;

        initial begin
            $readmemh("u_lut.hex", u_lut);
            $readmemh("v_lut.hex", v_lut);
        end
        
        
        Vec3 right;

    // right = cross(forward,up)
        wire [WIDTH-1:0]yz, zy;
        wire [WIDTH-1:0]xz, zx;
        wire [WIDTH-1:0]yx, xy;

        always_comb begin
            u = u_lut[pixel_x];
            v = v_lut[pixel_y];
        end
        
        always_ff @(posedge clk) begin
            if(reset) begin
                u_ff <= 0;
                v_ff <= 0; 
            end else begin
                u_ff <= u;
                v_ff <= v;
            end
        end
    
        // paralel right hesaplamaları
        logic [5:0]cross_valid;
        logic cross_valid_all;

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) YZ (
            .clk(clk),
            .start(pixel_valid),
            .a(cam.forward.y),
            .b(cam.up.z),
            .valid(cross_valid[0]),
            .result(yz)
        );
        
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) ZY (
            .clk(clk),
            .start(pixel_valid),
            .a(cam.forward.z),
            .b(cam.up.y),
            .valid(cross_valid[1]),
            .result(zy)
        );
        
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) ZX (
            .clk(clk),
            .start(pixel_valid),
            .a(cam.forward.z),
            .b(cam.up.x),
            .valid(cross_valid[2]),
            .result(zx)
        );
        
        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) XZ (
            .clk(clk),
            .start(pixel_valid),
            .a(cam.forward.x),
            .b(cam.up.z),
            .valid(cross_valid[3]),
            .result(xz)
        );

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) YX (
            .clk(clk),
            .start(pixel_valid),
            .a(cam.forward.y),
            .b(cam.up.x),
            .valid(cross_valid[4]),
            .result(yx)
        );

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) XY (
            .clk(clk),
            .start(pixel_valid),
            .a(cam.forward.x),
            .b(cam.up.y),
            .valid(cross_valid[5]),
            .result(xy)
        );

        assign right.x = yz - zy;
        assign right.y = zx - xz;
        assign right.z = xy - yx;
        assign cross_valid_all = &cross_valid;

        Vec3 scaled_right;
        Vec3 scaled_up;

        logic [5:0]scaled_valid;
        logic scaled_valid_all;

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) sr_x (
            .clk(clk),
            .start(cross_valid_all),
            .a(u_ff),
            .b(right.x),
            .valid(scaled_valid[0]),
            .result(scaled_right.x)
        );

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) sr_y (
            .clk(clk),
            .start(cross_valid_all),
            .a(u_ff),
            .b(right.y),
            .valid(scaled_valid[1]),
            .result(scaled_right.y)
        );

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) sr_z (
            .clk(clk),
            .start(cross_valid_all),
            .a(u_ff),
            .b(right.z),
            .valid(scaled_valid[2]),
            .result(scaled_right.z)
        );

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) su_x (
            .clk(clk),
            .start(cross_valid_all),
            .a(v_ff),
            .b(cam.up.x),
            .valid(scaled_valid[3]),
            .result(scaled_up.x)
        );

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) su_y (
            .clk(clk),
            .start(cross_valid_all),
            .a(v_ff),
            .b(cam.up.y),
            .valid(scaled_valid[4]),
            .result(scaled_up.y)
        );

        multiplication #(
            .WIDTH(WIDTH),
            .Q_BITS(Q_BITS)
        ) su_z (
            .clk(clk),
            .start(cross_valid_all),
            .a(v_ff),
            .b(cam.up.z),
            .valid(scaled_valid[5]),
            .result(scaled_up.z)
        );

        assign scaled_valid_all = &scaled_valid;

        Vec3 sum;

        assign sum.x = cam.forward.x + scaled_right.x;
        assign sum.y = cam.forward.y + scaled_right.y;
        assign sum.z = cam.forward.z + scaled_right.z;

        RayDirection normalization_in;  // forward + u*right + v*up;

        assign normalization_in.x = sum.x + scaled_up.x;
        assign normalization_in.y = sum.y + scaled_up.y;
        assign normalization_in.z = sum.z + scaled_up.z;

        logic norm_valid;
        RayDirection normalization_out;
        
        
        pipelined_normalization #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .DIV_COUNT(NORM_DIV_COUNT),
        .TAG_SIZE(TAG_SIZE)
        )normalize(
        .clk(clk),
        .reset(reset),
        .start(scaled_valid_all),
        .dir(normalization_in),
        .normal(normalization_out),
        .valid_out(norm_valid)
        );

        assign ray_out = '{
            origin : cam.origin,    // cam zaten sabit kalacak
            direction: normalization_out
        };
        assign valid_out = norm_valid;
        
    endmodule
