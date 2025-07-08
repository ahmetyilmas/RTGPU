`timescale 1ns / 1ps

module round_robin_arbiter #(
  parameter NUM_PORTS = 16
)(
  input  wire                  clk,
  input  wire                  reset,
  input  wire [NUM_PORTS-1:0] req_i,
  output logic [NUM_PORTS-1:0] gnt_o
);

  // Mask register to track last granted request
  logic [NUM_PORTS-1:0] mask_q, nxt_mask;

  // Update mask on grant
  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      mask_q <= {NUM_PORTS{1'b1}};
    else
      mask_q <= nxt_mask;
  end

  // Determine next mask based on which grant was active
  always_comb begin
      nxt_mask = mask_q;
           if (gnt_o[0])  nxt_mask = 16'b1111_1111_1111_1110;
      else if (gnt_o[1])  nxt_mask = 16'b1111_1111_1111_1100;
      else if (gnt_o[2])  nxt_mask = 16'b1111_1111_1111_1000;
      else if (gnt_o[3])  nxt_mask = 16'b1111_1111_1111_0000;
      else if (gnt_o[4])  nxt_mask = 16'b1111_1111_1110_0000;
      else if (gnt_o[5])  nxt_mask = 16'b1111_1111_1100_0000;
      else if (gnt_o[6])  nxt_mask = 16'b1111_1111_1000_0000;
      else if (gnt_o[7])  nxt_mask = 16'b1111_1111_0000_0000;
      else if (gnt_o[8])  nxt_mask = 16'b1111_1110_0000_0000;
      else if (gnt_o[9])  nxt_mask = 16'b1111_1100_0000_0000;
      else if (gnt_o[10]) nxt_mask = 16'b1111_1000_0000_0000;
      else if (gnt_o[11]) nxt_mask = 16'b1111_0000_0000_0000;
      else if (gnt_o[12]) nxt_mask = 16'b1110_0000_0000_0000;
      else if (gnt_o[13]) nxt_mask = 16'b1100_0000_0000_0000;
      else if (gnt_o[14]) nxt_mask = 16'b1000_0000_0000_0000;
      else if (gnt_o[15]) nxt_mask = 16'b0000_0000_0000_0000;
  end


  // Masked requests
  wire [NUM_PORTS-1:0] mask_req;
  assign mask_req = req_i & mask_q;

  wire [NUM_PORTS-1:0] mask_gnt;
  wire [NUM_PORTS-1:0] raw_gnt;

  // Instantiate day14 for masked and raw requests
  priority_arbiter #(NUM_PORTS) maskedGnt (.req_i(mask_req), .gnt_o(mask_gnt));
  priority_arbiter #(NUM_PORTS) rawGnt    (.req_i(req_i),    .gnt_o(raw_gnt));

  assign gnt_o = (|mask_req) ? mask_gnt : raw_gnt;

endmodule
