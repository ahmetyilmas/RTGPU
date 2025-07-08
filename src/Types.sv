`ifndef TYPES_SV
`define TYPES_SV

`define WIDTH 16
`define POW_WIDTH 256
`define Q_BITS 12 // Q3.12 format

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;
} RayDirection;


typedef struct packed {
    logic signed [`WIDTH-1:0] x;
    logic signed [`WIDTH-1:0] y;
    logic signed [`WIDTH-1:0] z;
} RayOrigin;

typedef struct packed {
    logic signed x;
    logic signed y;
    logic signed z;
} Min;

typedef struct packed {
    logic signed x;
    logic signed y;
    logic signed z;
} Max;

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;
} InvertedRayDirection;

`endif