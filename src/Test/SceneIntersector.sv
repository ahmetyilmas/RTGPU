`timescale 1ns / 1ps

`include "../Types.sv"
`include "../Parameters.sv"

module SceneIntersector#(
        parameter int WIDTH = 20,
        parameter int QBITS = 12, //Q4.20
        parameter int MAX20 = 20'h7FFFF,
        parameter int MIN20 = 20'h80000,
        parameter int PIXEL_WIDTH = 3,
        parameter int PIXEL_HEIGHT = 3,
        parameter int PIXEL_X = 8,
        parameter int PIXEL_Y = 8
    )(
        input clk,
        input reset,
        input start,
        input Cam_t camera_in
    );

    Camera cam;



    int counter = 0;
    int rg_counter = 0;
    always #5 clk = ~clk;


    Ray AABB_ray_in;
    Ray RG_ray_out;
    logic RayGen_valid;

    AABB aabb_box[3];
    AABB_result test_result[3];
    logic core_valid[3];


    logic RG_w;
    RayGenerator #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MIN(MIN20),
        .MAX(MAX20),
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .PIXEL_HEIGHT(PIXEL_HEIGHT)
    ) RayGen (
        .clk(clk),
        .reset(reset),
        .start(start),
        .cam(cam),
        .ray_out(RG_ray_out),
        .valid_out(RayGen_valid)
    );
    assign RG_w = RayGen_valid;


    assign AABB_ray_in = RG_ray_out;

    genvar i;
    generate
        for(i = 0; i < 3; i++) begin :AABB modules
            AABB #(
                .WIDTH(WIDTH),
                .Q_BITS(Q_BITS),
                .MAX(MAX20),
                .MIN(MIN20)
            ) AABB_CORE (
                .clk(clk),
                .reset(reset),
                .start(RayGen_valid),
                .ray_in(AABB_ray_in),
                .aabb_box(aabb_box[i]),
                .test_result(test_result[i]),
                .valid_out(core_valid[i])
            );
        end
    endgenerate

    Min tmins[3];
    Color colors[3];
    Color color_out;
    Min tmin;



    integer file;
    integer ray;
    initial begin
         file = $fopen("C:/Users/Ahmet/Desktop/output.txt", "w"); // "w" = yazma modunda aç
           if (file == 0) begin
               $display("Dosya açılamadı!");
               $finish;
           end else begin
               $display("Dosya açıldı.");
           end
        /*
        ray = $fopen("C:/Users/Ahmet/Desktop/RG_log.txt", "w");
        if (ray == 0) begin
           $display("RG_log açılamadı!");
           $finish;
       end else begin
           $display("RG_log açıldı.");
       end
       */

        reset = 1;
        start = 0;
        #10;
        reset = 0;
        start = 1;
        cam = '{
            origin : '{
                x : 20'h00000,
                y : 20'h00000,
                z : 20'hFE000   // -2.00
            },
            forward : '{
                x : 20'h00000,
                y : 20'h00000,
                z : 20'h01000   // +1.00
            },
            up : '{
            x : 16'd0,
            y : 16'h1000, // +1.0 yukarı yönü y ekseni
            z : 16'd0
            },
            fov: 20'd1934,
            aspect_ratio : 20'h01000
        };

        // Kırmızı Kutu
        aabb_box[0] = '{        // (-1.0, +1.0, +1.0)
            min : '{
                x : 20'h00000, //  0.00
                y : 20'h00000, //  0.00
                z : 20'hFF000  // -1.00
            },
            max : '{
                x : 20'h00C00, // +0.75
                y : 20'h00C00, // +0.75
                z : 20'h01000  // +1.00
            },
            color : '{
                r : 8'hFF,
                g : 8'h00,
                b : 8'h00
            }
        };
        // Yeşil kutu
        aabb_box[1] = '{
            min : '{
                x : 20'hFF400, // -0.75
                y : 20'h00000, //  0.00
                z : 20'hFF000  // -1.00
            },
            max : '{
                x : 20'h00000, //  0.00
                y : 20'h00C00, // +0.75
                z : 20'h01000  // +1.00
            },
            color : '{
                r : 8'h00,
                g : 8'hFF,
                b : 8'h00
            }
        };
        // Mavi kutu
        aabb_box[2] = '{
            min : '{
                x : 20'hFF400, // -0.75
                y : 20'hFF400, // -0.75
                z : 20'hFF000  // -1.00
            },
            max : '{
                x : 20'h00C00, // +0.75
                y : 20'h00000, //  0.00
                z : 20'h01000  // +1.00
            },
            color : '{
                r : 8'h00,
                g : 8'h00,
                b : 8'hFF
            }
        };
        repeat(5000) @(posedge clk);
        $fclose(file);
        $finish;
    end
    logic write_enable;
    logic write_rg;

    assign write_rg = RayGen_valid;

    always_ff @(posedge clk) begin
        if(reset) begin
            tmins[0] = MAX20;
            tmins[1] = MAX20;
            tmins[2] = MAX20;
            color_out = '{r: 8'h00, g : 8'h00, b : 8'h00};
            write_enable = 0;
        end else begin
            if(core_valid[0] && core_valid[1] && core_valid[2]) begin

                tmins[0] = test_result[0].ray_hit ? test_result[0].tmin : MAX20;
                colors[0] = test_result[0].ray_hit ?
                    test_result[0].box.color : '{r : 8'h00, g : 8'h00, b : 8'h00};

                tmins[1] = test_result[1].ray_hit ? test_result[1].tmin : MAX20;
                colors[1] = test_result[1].ray_hit ?
                    test_result[1].box.color : '{r : 8'h00, g : 8'h00, b : 8'h00};

                tmins[2] = test_result[2].ray_hit ? test_result[2].tmin : MAX20;
                colors[2] = test_result[2].ray_hit ?
                    test_result[2].box.color : '{r : 8'h00, g : 8'h00, b : 8'h00};

               color_out = tmins[0] < tmins[1] ? (tmins[0] < tmins[2] ? colors[0] : colors[2]) :
                    (tmins[1] < tmins[2] ? colors[1] : colors[2]);


                write_enable = 1;
            end else begin
                write_enable = 0;
            end
        end
    end
        always_ff @(posedge clk) begin
            if(write_enable) begin
                if(counter < PIXEL_X * PIXEL_Y) begin
                $fwrite(file, "%0d %0d %0d\n", color_out.r, color_out.g, color_out.b);
                $display("Dosyaya yazıldı. counter:", counter);
                $display("Renkler: %0d %0d %0d", color_out.r, color_out.g, color_out.b);

                end else begin
                    $fclose(file);
                    $finish;
                end
                counter++;
            end
        end
        /*
        always_ff @(posedge clk) begin
            if(write_rg) begin
                if(rg_counter < `PIXEL_X*`PIXEL_Y) begin
                $fwrite(ray, "%0h %0h %0h\n", RG_ray_out.direction.x, RG_ray_out.direction.y, RG_ray_out.direction.z); // her satıra RGB
                //$display("Dosyaya yazıldı. counter:", counter);
                //$display("Renkler: %0d %0d %0d", color_out.r, color_out.g, color_out.b);
                end else begin
                    $fclose(ray);
                    $finish;
                end
                rg_counter++;
            end
        end
        */
endmodule
