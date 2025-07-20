`timescale 1ns / 1ps
`include "Types.sv"

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
    
    localparam WIDTH = `WIDTH;
    localparam Q_BITS = `Q_BITS;
    localparam DIV_COUNT = 24;
    localparam MAX16 = `MAX_16;
    localparam MIN16 = `MIN_16;
    localparam TAG_SIZE = `TAG_SIZE;
    localparam tan_fov = `tan_fov_half_16;
    localparam PIXEL_WIDTH = `PIXEL_WIDTH;
    localparam PIXEL_HEIGHT = `PIXEL_HEIGHT;
    localparam OBJECT_COUNT = 1;

    Camera cam;


    logic clk = 0;
    logic reset = 0;
    logic start = 0;

    int counter = 0;
    always #5 clk = ~clk;


    Ray AABB_ray_in;
    Ray RG_ray_out;
    logic RayGen_valid;

    AABB aabb_box[2:0];
    AABB_result test_result[2:0];
    logic core_valid[2:0];

    RayGenerator #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .MIN(MIN16),
        .MAX(MAX16),
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
    
    assign AABB_ray_in = RG_ray_out;
    
    genvar i;
    generate
        for(i = 0; i < 1; i++) begin
            AABB #(
                .WIDTH(WIDTH),
                .Q_BITS(Q_BITS),
                .MAX(MAX16),
                .MIN(MIN16)
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
    
    Min tmin;
    //Color colors[2:0];
    Color color_out;
    
    
    
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
                x : 16'h0,
                y : 16'h0,
                z : 16'hD000
            },
            forward : '{
                x : 16'h0000,
                y : 16'h0000,
                z : 16'h1000
            },
            up : '{
            x : 16'd0,
            y : 16'h1000, // +1.0 yukarı yönü y ekseni
            z : 16'd0
            },
            fov: 16'd2457,
            aspect_ratio : 16'h1000      
        };

        aabb_box[0] = '{
            min : '{
                x : 16'hF000,
                y : 16'h1000,
                z : 16'h1000
            },
            max : '{
                x : 16'h1000,
                y : 16'h3000,
                z : 16'h3000
            },
            color : '{
                r : 8'hFF,
                g : 8'h00,
                b : 8'h00
            }
        };
        aabb_box[1] = '{
            min : '{
                x : 16'hE000,
                y : 16'hE000,
                z : 16'hE000
            },
            max : '{
                x : 16'hD000,
                y : 16'hD000,
                z : 16'hD000
            },
            color : '{
                r : 8'h00,
                g : 8'hFF,
                b : 8'h00
            }
        };
        aabb_box[2] = '{
            min : '{
                x : 16'hF000,
                y : 16'h2000,
                z : 16'hF000
            },
            max : '{
                x : 16'h1000,
                y : 16'h4000,
                z : 16'h1000
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
        
    always_ff @(posedge clk) begin
        if(reset) begin
            tmin = MAX16;
            color_out = '{r : 8'h00, g : 8'h00, b : 8'h00};
            write_enable = 0;
        end else begin
            if(core_valid[0]/* && core_valid[1] && core_valid[2]*/) begin
        
                tmin = test_result[0].ray_hit ? test_result[0].tmin : MAX16;
                color_out = test_result[0].ray_hit ? test_result[0].box.color : '{r : 8'h00, g : 8'h00, b : 8'h00};
        
                write_enable = 1;
            end else begin
                write_enable = 0;
            end
        end
    end
        always_ff @(posedge clk) begin
            if(write_enable) begin
                if(counter < `PIXEL_X*`PIXEL_Y) begin
                $fwrite(file, "%0d %0d %0d\n", color_out.r, color_out.g, color_out.b); // her satıra RGB
                $display("Dosyaya yazıldı. counter:", counter);
                $display("Renkler: %0d %0d %0d", color_out.r, color_out.g, color_out.b);
                
                end else begin
                    $fclose(file);
                    $finish;
                end
                counter++;
            end
        end
    

endmodule