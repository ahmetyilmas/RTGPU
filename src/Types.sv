`ifndef TYPES_SV
`define TYPES_SV

`define WIDTH 16
`define POW_WIDTH 256
`define Q_BITS 12 // Q3.12 format

`define MAX_16 16'h7FFF       // Q3.12 format
`define MIN_16 16'h8000
`define MAX_32 32'h7FFFFFFF   // Q16.16 format
`define MIN_32 32'h80000000

`define tan_fov_half_16 16'h093D // tan(fov/2) fov = 60


`define PIXEL_WIDTH 10 // 2^10 = 1024 640p icin yeterli
`define PIXEL_HEIGHT 9 // 2^9 = 512 480p icin yeterli

`define PIXEL_X 640
`define PIXEL_Y 480

`define TAG_SIZE 64

typedef struct packed {
    logic signed [`WIDTH-1:0] x;
    logic signed [`WIDTH-1:0] y;
    logic signed [`WIDTH-1:0] z;
} Vec3;

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;
} RayDirection;


// a tag added for async calculations
typedef struct packed {
    RayDirection direction;
    logic [`TAG_SIZE-1:0] tag;
} TaggedDirection;

// pow of x,y,z vectors before sqrt calc
typedef struct packed {
    RayDirection direction;
    logic [`TAG_SIZE:0] tag;
    Vec3 pow;
} TaggedDirection_pow;

typedef struct packed {
    RayDirection direction;
    logic [`TAG_SIZE:0]tag;
    logic signed [`WIDTH-1:0]len;
} TaggedDirection_len;

typedef struct packed {
    logic signed [`WIDTH-1:0] x;
    logic signed [`WIDTH-1:0] y;
    logic signed [`WIDTH-1:0] z;
} RayOrigin;


typedef struct packed {
    RayDirection direction;
    RayOrigin origin;
} Ray;

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;
} Min;

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;
} Max;

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;
} InvertedRayDirection;

typedef enum logic[1:0]{
    BUSY =      2'b00,  // birim bir veriyi isliyor ve yeni veri alamaz
    IDLE =      2'b01,  // birim bosta duruyor yeni veri kabul edebilir
    WAITING =   2'b10,  // birim mevcut islemi bitirmis ama sonraki cikis bekliyor
    ACCEPTING = 2'b11   // birim bir veri isliyor ama yeni veri alabilir
}state;



typedef struct packed {
    Min min;
    Max max;
} AABB;

typedef struct packed {
    logic [7:0]r;
    logic [7:0]g;
    logic [7:0]b;
} Color;

typedef struct packed {
    Color color;
    AABB box;
} SceneObject;

typedef struct packed {
    RayOrigin origin;                      // kamera konumu
    Vec3 forward;                       // bakis yonu
    Vec3 up;                            // yukari bakis yonu
    logic signed [`WIDTH-1:0] fov;             // gorus acisi
    logic signed [`WIDTH-1:0] aspect_ratio;    // genislik/yukseklik orani
}Camera;

`endif