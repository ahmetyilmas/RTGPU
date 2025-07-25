`ifndef PARAMETERS_SV
`define PARAMETERS_SV

`define WIDTH 20
`define Q_BITS 12   // Q7.12 format

// Q3.12 format
`define MAX_16 16'h7FFF
`define MIN_16 16'h8000

// Q16.16 format
`define MAX_32 32'h7FFFFFFF
`define MIN_32 32'h80000000

// Q7.16 format
`define MAX_24 24'h7FFFFF
`define MIN_24 24'h800000

// Q7.12 format
`define MIN_20 20'h80000
`define MAX_20 20'h7FFFF

// 8x8 cozunurluk.
`define PIXEL_X 8     // 640
`define PIXEL_Y 8     // 480

`define TANFOVHALF_16 16'h093D // tan(fov/2) fov = 60

`endif
