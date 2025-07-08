`timescale 1ns / 1ps


module priority_arbiter #(
    NUM_PORTS = 16
    )(
    input       wire[NUM_PORTS-1:0] req_i,  // istekte bulunan port
    output      wire[NUM_PORTS-1:0] gnt_o   // izin verilen port (One-hot sinyal)
    );
    
    // Port[0] en yuskek oncelikli
    assign gnt_o[0] = req_i[0];
    
    genvar i;
    for (i=1; i<NUM_PORTS; i=i+1) begin
        assign gnt_o[i] = req_i[i] & ~(|gnt_o[i-1:0]);
    end
    
    
    
endmodule
