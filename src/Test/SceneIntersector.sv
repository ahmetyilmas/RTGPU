`timescale 1ns / 1ps

`include "Types.sv"
`include "Parameters.sv"

/*
Bu modulde RayGenerator ile kameranin konumuna gore Ray olusturulur. Bu Ray'lere bir Tag atanir.
Daha sonra Scene olusturulur. Scene 3 objeden olusur.
Olusturulan 3 Scene objesi paralel olarak calisan 3 AABB modulune verilir.
AABB modulunden Tag bilgisi, Color, tmin ve ray_hit ciktisi alinir.
AABB modulunden alinan ciktilara gore Tag'ler eslesir ve ray_hit = 1 olan ciktilardan
tmin'i en kucuk olan secilir. En sonunda o pixel'in rengi tmin'i en kucuk olan
AABB ciktisinin rengi olur.
*/

module SceneIntersector();

    localparam int WIDTH = 24;
    localparam int Q_BITS = 12; //Q4.20
    localparam int MAX24 = 24'h7FFFFF;
    localparam int MIN24 = 24'h800000;
    localparam int PIXEL_WIDTH = 8;
    localparam int PIXEL_HEIGHT = 8;

    Camera cam;


    logic clk = 0;
    logic reset = 0;
    logic start = 0;

    int counter = 0;
    int rg_counter = 0;
    always #5 clk = ~clk;


    Ray AABB_ray_in;
    Ray RG_ray_out;
    logic RayGen_valid;

    AABB aabb_box[4];
    AABB_result_t test_result[4];
    logic core_valid[4];

    AABB_result_t no_hit = '{
        box: '{
            min: '{
                x: MIN24,
                y: MIN24,
                z: MIN24
            },
            max: '{
                x: MAX24,
                y: MAX24,
                z: MAX24
            },
            color: '{
                r: 8'h00,
                g: 8'h00,
                b: 8'h00
            }
        },
        ray_hit: 0,
        tmin: MAX24,
        normal: '{
            x: 24'h0,
            y: 24'h0,
            z: 24'h0
        }
    };

    logic RG_w;
    RayGenerator #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MIN(MIN24),
        .MAX(MAX24),
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
        for(i = 0; i < 4; i++) begin
            AABB #(
                .WIDTH(WIDTH),
                .Q_BITS(Q_BITS),
                .MAX(MAX24),
                .MIN(MIN24)
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

    Min tmins[4];
    AABB_result_t aabb_final;
    logic write_enable;
    logic LS_start;
    assign LS_start = core_valid[0];
    always_comb  begin
            if(core_valid[0] && core_valid[1] && core_valid[2] && core_valid[3]) begin

                tmins[0] = test_result[0].ray_hit ? test_result[0].tmin : MAX24;
                tmins[1] = test_result[1].ray_hit ? test_result[1].tmin : MAX24;
                tmins[2] = test_result[2].ray_hit ? test_result[2].tmin : MAX24;
                tmins[3] = test_result[3].ray_hit ? test_result[3].tmin : MAX24;

                if(!test_result[0].ray_hit && !test_result[1].ray_hit &&
                    !test_result[2].ray_hit && !test_result[3].ray_hit) begin
                    aabb_final = no_hit;
                end else begin
                    aabb_final = tmins[0] < tmins[1] ? (tmins[0] < tmins[2] ? (tmins[0] < tmins[3] ? test_result[0] : test_result[3]):
                    tmins[2] < tmins[3] ? test_result[2] : test_result[3]) : (tmins[1] < tmins[2] ? (tmins[1] < tmins[3] ? test_result[1] : test_result[3]) :
                    tmins[2] < tmins[3] ? test_result[2] : test_result[3]);
                end

            end else begin
                aabb_final = no_hit;
            end
    end

    Color finalColor;
    LightSource_t lightSource;

    LambertianShader #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS)
    ) LS (
        .clk(clk),
        .reset(reset),
        .start(LS_start),
        .aabb_in(aabb_final),
        .lightSource_in(lightSource),
        .finalColor_out(finalColor),
        .valid_out(write_enable)
    );

    integer file;

    initial begin
         file = $fopen("C:/Users/Ahmet/Desktop/output.txt", "w"); // "w" = yazma modunda aç
           if (file == 0) begin
               $display("Dosya açılamadı!");
               $finish;
           end else begin
               $display("Dosya açıldı.");
           end

        reset = 1;
        start = 0;
        #10;
        reset = 0;
        start = 1;
        cam = '{
            origin : '{
                x : 24'h000000,
                y : 24'h000000,
                z : 24'hFFE000   // -2.00
            },
            forward : '{
                x : 24'h000000,
                y : 24'h000000,
                z : 24'h001000   // +1.00
            },
            up : '{
            x : 24'd0,
            y : 24'h001000, // +1.0 yukarı yönü y ekseni
            z : 24'd0
            },
            fov: 24'd1934,
            aspect_ratio : 24'h001000
        };

        // Kırmızı Kutu
        aabb_box[0] = '{        // (-1.0, +1.0, +1.0)
            min : '{
                x : 24'h000000, //  0.00
                y : 24'h000000, //  0.00
                z : 24'hFFF000  // -1.00
            },
            max : '{
                x : 24'h000C00, // +0.75
                y : 24'h000C00, // +0.75
                z : 24'h001000  // +1.00
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
                x : 24'hFFF400, // -0.75
                y : 24'h000000, //  0.00
                z : 24'hFFF000  // -1.00
            },
            max : '{
                x : 24'h000000, //  0.00
                y : 24'h000C00, // +0.75
                z : 24'h001000  // +1.00
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
                x : 24'h000000, //  0.00
                y : 24'hFFF400, // -0.75
                z : 24'hFFF000  // -1.00
            },
            max : '{
                x : 24'h000C00, // +0.75
                y : 24'h000000, //  0.00
                z : 24'h001000  // +1.00
            },
            color : '{
                r : 8'h00,
                g : 8'h00,
                b : 8'hFF
            }
        };
        // Sari kutu
        aabb_box[3] = '{
            min : '{
                x : 24'hFFF400, // -0.75
                y : 24'hFFF400, // -0.75
                z : 24'hFFF000  // -1.00
            },
            max : '{
                x : 24'h000000, //  0.00
                y : 24'h000000, //  0.00
                z : 24'h001000  // +1.00
            },
            color : '{
                r : 8'hFF,
                g : 8'hFF,
                b : 8'h00
            }
        };
        // Isik kaynagi

        lightSource = '{
            ray: '{
                origin : '{
                    x : 24'h000000,
                    y : 24'h000000,
                    z : 24'hFFE000   // -2.00
            },
                direction: '{
                    x : 24'h000000,
                    y : 24'h000000,
                    z : 24'hFFF000
                }
            },
            ray_color: '{
                r: 8'hFF,
                g: 8'hFF,
                b: 8'hFF
            }
        };
        repeat(5000) @(posedge clk);
        $fclose(file);
        $finish;
    end

    logic write_rg;

    assign write_rg = RayGen_valid;


        always_ff @(posedge clk) begin
            if(write_enable) begin
                if(counter < `PIXEL_X*`PIXEL_Y) begin
                $fwrite(file, "%0d %0d %0d\n", finalColor.r, finalColor.g, finalColor.b);
                $display("Dosyaya yazıldı. counter:", counter);
                //$display("Renkler: %0d %0d %0d", color_out.r, color_out.g, color_out.b);

                end else begin
                    $fclose(file);
                    $finish;
                end
                counter++;
            end
        end
endmodule
