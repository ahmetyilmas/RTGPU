`timescale 1ns / 1ps
`include "Types.sv"


module AABB #(
    parameter WIDTH = `WIDTH,
    parameter Q_BITS = `Q_BITS,
    parameter DIV_COUNT = 16,
    parameter MAX = `MAX_16,
    parameter MIN = `MIN_16,
    parameter TAG_SIZE = `TAG_SIZE
)(
    input clk,
    input reset,
    input start,
    input TaggedRay ray_in, // origin, direction, tag bilgileri
    input AABB aabb_box,    // min, max, color bilgileri
    output AABB_result test_result,
    output logic valid
);
    
    logic ray_hit_x,ray_hit_y,ray_hit_z;
    logic start_inv;
    logic skip_inv;
    always_comb begin
        if(start) begin
            if(ray_in.direction.x == 0) begin
                if(!(ray_in.origin.x >= aabb_box.min.x & ray_in.origin.x <= aabb_box.max.x))
                    ray_hit_x = 0;
                else
                    ray_hit_x = 1;
            end else
                ray_hit_x = 1;
    
            if(ray_in.direction.y == 0) begin
                if(!(ray_in.origin.y >= aabb_box.min.y & ray_in.origin.y <= aabb_box.max.y)) begin
                    ray_hit_y = 0;
                end else begin
                    ray_hit_y = 1;
                end 
            end else 
                ray_hit_y = 1;
            if(ray_in.direction.z == 0) begin
                if(!(ray_in.origin.z >= aabb_box.min.z & ray_in.origin.z <= aabb_box.max.z)) begin
                    ray_hit_z = 0;
                end else begin
                    ray_hit_z = 1;
                end
            end else
                ray_hit_z = 1;
            
            
        end
    end
    assign start_inv = start;
    // eger ilk kontrolde hicbir vektor carpmiyorsa bu tag'i fifoya ekle
    assign skip_inv = (!ray_hit_x | !ray_hit_y | !ray_hit_z);
    
    /*
    AABB'ye giren en yeni ray'in atlanıp atlanmayacagina karar verdikten sonra direkt cikarilmasi
    kararsizlik olusturur. Eger bir ray'in atlanmasina karar verildigi anda t_calc'den de valid 
    gelirse atamanin yapilacagi blokta atlanacak olan ray mi yoksa t_calc'den gelen ray mi atanacak
    bilinemez. Bu sorunun cozumu icin implement edilebilecek yaklasimlar soyledir:
    
    1. Eger bir ray'in atlanilacagina karar verilirse fifoya o ray'in tag'i yazilir. 
    t_calc'den cikan son verinin tag'indan bir sonraki tag bir register'da tutulur ve eger fifodaki 
    siradaki okunacak tag bu tag ile ayni ise fifodaki tag secilir ve ray_hit=0 ve tmin=MAX olacak sekilde cikis verilir.
    bu durum t_calc ile cakismaya sebep olmaz. skip_inv 1 oldugu an ters cevirip carpma islemine de start verilmediginden
    en az 1 cycle valid=0 olacaktir. Fakat bu cozum inverted_direction ve sorted_fifo'ya modifikasyon yapmayi gerektirir.
    Cunku ilgili tag, inverted_direction'a girmediginde sorted_fifo bu tag'i bekleyecek fakat bu tag giris yapmadigindan
    deadlock'a girecektir. 

    2. skip_inv = 1 oldugunda ters cevirip carpma isleminin 1 cycle yapilmayacagindan ve 1 cycle valid = 0 olacagindan bahsedilmisti.
    valid = 0 oldugu anlarda direkt cikis vermek de bir secenek olabilir. Cunku fifo ve register kullanilmayip kaynaktan 
    tasarruf edilebilirdi fakat bu yaklasim verilerin sirayla cikisini garanti etmez. valid = 0 oldugu anda start
    cikmasi beklenen ray icin start verilmis olabilir fakat bolme islemi de uzun surdugunden henuz cikis yapmamis olabilir.
    Dolayisiyla valid = 0 oldugu anlarda araya atlanmis ray tag'i sıkıstırmak pek kararli degil. Ayrica sıkıstırma yapabilmek
    icin en az 2 cycle valid = 0 olmasi gerekli(1 cycle fifo'dan okuma + 1 cycle cikisa FF'lere atama).

    3. Is hattina mudahale edilmeyip her turlu ters cevirip carpma islemi yapilmasi da bir secenek olabilir(!).
    Fakat atlama yapilmadan hesap yapildiginda alinan ray_hit ve tmin sonucu yaniltici olabilir. Yapilan bazi testbenchlerde
    carpmamasi gerektigi bilinen bir Ray always_comb'daki origin - tmin(veya tmax) araligi kontrolu olmadigi icin ters cevirip
    carpma kisminda tmin = 0 cikarmadigi durumlar oldu.

    4. 1. ve 3. cozum ayni anda kullanilacaktir. Atlanacak ray'in tag'i fifo'da tutulacak ama bu tag'a ait ray yine ters cevirip 
    carpma islemine tabii tutulacaktir. t_calc sonrasi bir register eklenip t_calc'den cikacak tag'dan sonraki tag bu register'da
    tutulacaktir. Bu register'a atlanacak olan tag  geldiginde t_calc'den valid gelmesine ragmen cikislara yine de tmin = MAX ve 
    ray_hit = 0 atamalari yapilacaktir.
    */

    logic [TAG_SIZE-1:0]skipped_tag;
    logic [TAG_SIZE-1:0]skipped_tag_ff;
    logic hit_fifo_ready;
    logic hit_fifo_valid;
    logic bring_next_tag;

    fifo #(
        .WIDTH(TAG_SIZE+1),
        .DEPTH(DIV_COUNT)
    ) hit_fifo (
        .clk(clk),
        .reset(reset),
        .read(bring_next_tag),
        .write(skip_inv),
        .data_in(ray_in.tag),
        .data_out(skipped_tag),
        .ready(hit_fifo_ready),
        .overflow(),
        .valid_out(hit_fifo_valid)
    );


    TaggedDirection dir_in;
    
    assign dir_in = '{
        direction : ray_in.direction,
        tag : ray_in.tag
    };

    TaggedDirection inv_dir;
    logic valid_inv;
    
    inverted_direction #(
        .WIDTH(WIDTH),
        .Q_BITS(Q_BITS),
        .TAG_SIZE(TAG_SIZE),
        .DIV_COUNT(DIV_COUNT)
    ) invert (
        .clk(clk),
        .reset(reset),
        .start(start_inv),
        .direction_in(dir_in),
        .inv_dir_out(inv_dir),
        .valid_out(valid_inv)
    );
    
    
    TaggedVec3 t_xyz_1;
    TaggedVec3 t_xyz_2;
    
    logic signed [WIDTH-1:0] mul_tx1, mul_tx2, mul_ty1, mul_ty2, mul_tz1, mul_tz2;
    logic signed [WIDTH-1:0] tx1, tx2, ty1, ty2, tz1, tz2;
    logic signed [WIDTH-1:0] tminx, tminy, tminz;
    logic signed [WIDTH-1:0] tmaxx, tmaxy, tmaxz;
    logic signed [WIDTH-1:0] tmin, tmax;
    logic signed [WIDTH-1:0] max_tmin;
    logic signed [WIDTH-1:0] tmin_out;
    
    
    logic ray_hit;
    logic [TAG_SIZE-1:0] tag_out; 

    logic valid_tx1, valid_tx2;
    logic valid_ty1, valid_ty2;
    logic valid_tz1, valid_tz2;
    logic valid_all;
    
    assign tx1 = aabb_box.min.x - ray_in.origin.x;
    assign tx2 = aabb_box.max.x - ray_in.origin.x;
    assign ty1 = aabb_box.min.y - ray_in.origin.y;
    assign ty2 = aabb_box.max.y - ray_in.origin.y;
    assign tz1 = aabb_box.min.z - ray_in.origin.z;
    assign tz2 = aabb_box.max.z - ray_in.origin.z;
    

    logic [TAG_SIZE-1:0] tag_register;
    logic override;

    always_ff @(posedge clk) begin
        if(reset) begin
            tag_register   <= 0;
            //skipped_tag_ff <= 0;
            bring_next_tag <= 1;
            override       <= 0;
        // atlanacak tag ile inverted_direction'dan gelen tag ayniysa t_calc'dan gelen veriyi 
        // kullanma ve fifo'da atlanacak tag varsa getir.
        end else if(skipped_tag_ff == inv_dir.tag) begin
            override       <= 1;
            bring_next_tag <= hit_fifo_ready ? 1 : 0;
            tag_register   <= inv_dir.tag;
        // eger atlanacak tag'i inverted_direction'dan gelmesini bekliyorsak fifodan yeni tag getirme
        end else if(skipped_tag_ff > inv_dir.tag) begin
            override       <= 0;
            bring_next_tag <= 0;
            tag_register   <= inv_dir.tag;  // inverted_diraction'dan yeni tag getir.

        // eger atlanacak tag ile inverted_direction'dan gelen tag eslestiyse fakat o anda fifo'da henuz atlanacak
        // tag yoksa yeni tag getirilmemistir. atlanacak tag kucuk register'daki tag'dan kucuk kaldiysa ve fifoya
        // atlanacak veri geldiyse atlanacak tag'i getir.
        end else if(skipped_tag_ff <= inv_dir.tag && hit_fifo_ready) begin
            bring_next_tag <= 1;
        end else if(bring_next_tag && hit_fifo_ready)begin
            skipped_tag_ff <= skipped_tag;
            bring_next_tag <= 0;
        end else if(bring_next_tag && !hit_fifo_ready) begin
            bring_next_tag <= 1;
        end else if(valid_inv) begin
            tag_register   <= inv_dir.tag;
        end else begin
            override       <= 0;
            bring_next_tag <= 1;
            tag_register   <= inv_dir.tag;
        end
    end
    
    
    logic [1:0]t_calc_valid;
    // asagidaki t_calc modulleri paralel calisiyor ve cikti vermesi 1 cycle suruyor.
    // inverted_direction ile bu moduller arasina koyulacak tag_register ile 
    // atlama yapilmasi durumunda senkronizasyon saglanmis olur.

    t_calc #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS),
    .TAG_SIZE(TAG_SIZE)
    )t1 (
    .clk(clk),
    .start(valid_inv),
    .dir_in_a(inv_dir),
    .tx(tx1),
    .ty(ty1),
    .tz(tz1),
    .valid(t_calc_valid[0]),
    .TD_out(t_xyz_1)
    );
    
    t_calc #(
    .WIDTH(WIDTH),
    .Q_BITS(Q_BITS),
    .TAG_SIZE(TAG_SIZE)
    )t2 (
    .clk(clk),
    .start(valid_inv),
    .dir_in_a(inv_dir),
    .tx(tx2),
    .ty(ty2),
    .tz(tz2),
    .valid(t_calc_valid[1]),
    .TD_out(t_xyz_2)
    );
    
    assign mul_tx1 = (inv_dir.direction.x == MAX) ? MIN : t_xyz_1.x;
    assign mul_tx2 = (inv_dir.direction.x == MAX) ? MAX : t_xyz_2.x;
    assign mul_ty1 = (inv_dir.direction.y == MAX) ? MIN : t_xyz_1.y;
    assign mul_ty2 = (inv_dir.direction.y == MAX) ? MAX : t_xyz_2.y;
    assign mul_tz1 = (inv_dir.direction.z == MAX) ? MIN : t_xyz_1.z;
    assign mul_tz2 = (inv_dir.direction.z == MAX) ? MAX : t_xyz_2.z;


    assign valid_all = &t_calc_valid;
    
    


    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            ray_hit <= 0;
            tmin_out <= 0;
            valid <= 0;
        end else if(!override && valid_all) begin
            tminx = (mul_tx1 < mul_tx2) ? mul_tx1 : mul_tx2;
            tmaxx = (mul_tx1 > mul_tx2) ? mul_tx1 : mul_tx2;
            tminy = (mul_ty1 < mul_ty2) ? mul_ty1 : mul_ty2;
            tmaxy = (mul_ty1 > mul_ty2) ? mul_ty1 : mul_ty2;
            tminz = (mul_tz1 < mul_tz2) ? mul_tz1 : mul_tz2;
            tmaxz = (mul_tz1 > mul_tz2) ? mul_tz1 : mul_tz2;
    
            tmin = (tminx > tminy) ? ((tminx > tminz) ? tminx : tminz) : ((tminy > tminz) ? tminy : tminz);
            tmax = (tmaxx < tmaxy) ? ((tmaxx < tmaxz) ? tmaxx : tmaxz) : ((tmaxy < tmaxz) ? tmaxy : tmaxz);
            
            
            max_tmin = (tmin >= 0) ? tmin : 0;
            ray_hit = (tmax >= max_tmin);
            tag_out <= t_xyz_1.tag;
            tmin_out = ray_hit ? max_tmin : 0;
            valid <= 1;
        end else if (override) begin
            ray_hit = 0;
            valid <= 1;
            tmin_out = MAX;
        end else begin
            valid <= 0;
        end
    end
    
    always_comb begin
        if(valid) begin
            test_result = '{
                box : aabb_box,
                ray_hit : ray_hit,
                tag : tag_out,
                tmin : tmin_out
            };
        end
    end
    
    
endmodule
