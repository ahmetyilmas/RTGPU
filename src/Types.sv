`ifndef TYPES_SV
`define TYPES_SV

typedef struct packed {
    logic signed [`WIDTH-1:0] x;
    logic signed [`WIDTH-1:0] y;
    logic signed [`WIDTH-1:0] z;
} Vec3;

typedef struct packed {
    logic signed [`WIDTH-1:0] x;
    logic signed [`WIDTH-1:0] y;
    logic signed [`WIDTH-1:0] z;
} Vec3_t;

typedef struct packed {
    logic signed [`WIDTH-1:0] x;
    logic signed [`WIDTH-1:0] y;
    logic signed [`WIDTH-1:0] z;
    logic [`TAG_SIZE-1:0] tag;
} TaggedVec3;

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;
} RayDirection;

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;

    logic signed [`WIDTH-1:0]len;
} RayDirection_len;

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;

    logic signed [`WIDTH-1:0]sqr_x;
    logic signed [`WIDTH-1:0]sqr_y;
    logic signed [`WIDTH-1:0]sqr_z;
} RayDirection_sqr;

// a tag added for async calculations
typedef struct packed {
    RayDirection direction;
    logic [`TAG_SIZE-1:0] tag;
} TaggedDirection;

// pow of x,y,z vectors before sqrt calc
typedef struct packed {
    RayDirection direction;
    logic [`TAG_SIZE-1:0] tag;
    Vec3 pow;
} TaggedDirection_pow;

typedef struct packed {
    RayDirection direction;
    logic [`TAG_SIZE-1:0]tag;
    logic signed [`WIDTH-1:0]len;
} TaggedDirection_len;

typedef struct packed {
    logic signed [`WIDTH-1:0] x;
    logic signed [`WIDTH-1:0] y;
    logic signed [`WIDTH-1:0] z;
} RayOrigin;

typedef struct packed {
    RayDirection direction;
    logic [`TAG_SIZE-1:0]tag;
} TaggedNormalized;

typedef struct packed {
    RayDirection direction;
    RayOrigin origin;
} Ray;

typedef struct packed {
    RayDirection direction;
    RayOrigin origin;
    logic [`TAG_SIZE-1:0] tag;
} TaggedRay;

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

typedef struct packed {
    logic signed [`WIDTH-1:0]x;
    logic signed [`WIDTH-1:0]y;
    logic signed [`WIDTH-1:0]z;
} TaggedInvertedRayDirection;

typedef enum logic[1:0]{
    S0_BUSY =      2'b00,  // birim bir veriyi isliyor ve yeni veri alamaz
    S1_IDLE =      2'b01,  // birim bosta duruyor yeni veri kabul edebilir
    S2_WAITING =   2'b10,  // birim mevcut islemi bitirmis ama sonraki cikis bekliyor
    S3_ACCEPTING = 2'b11   // birim bir veri isliyor ama yeni veri alabilir
}state_t;

typedef struct packed {
    logic [7:0]r;
    logic [7:0]g;
    logic [7:0]b;
} Color;

typedef struct packed {
    Min min;
    Max max;
    Color color;
} AABB;

typedef struct packed {
    AABB [`BOX_COUNT-1:0]box;
} SceneObject;

typedef struct packed {
    AABB box;
    logic ray_hit;
    logic [`WIDTH-1:0] tmin;
} AABB_result;

typedef struct packed {
    AABB box;
    logic ray_hit;
    logic [`WIDTH-1:0] tmin;
    Vec3_t normal;
} AABB_result_t;

typedef struct packed {
    AABB box;
    logic ray_hit;
    logic [`WIDTH-1:0] tmin;
    Vec3_t normal;
} Intersection_result_t;


typedef struct packed {
    RayOrigin origin;                           // kamera konumu
    Vec3 forward;                               // bakis yonu
    Vec3 up;                                    // yukari bakis yonu
    logic signed [`WIDTH-1:0] fov;              // gorus acisi
    logic signed [`WIDTH-1:0] aspect_ratio;     // genislik/yukseklik orani
}Camera;

typedef struct packed {
    RayOrigin origin;                           // kamera konumu
    Vec3_t forward;                             // bakis yonu
    Vec3_t up;                                  // yukari bakis yonu
    logic signed [`WIDTH-1:0] fov;              // gorus acisi
    logic signed [`WIDTH-1:0] aspect_ratio;     // genislik/yukseklik orani
}Camera_t;

typedef struct {
  logic [31:0] addr;
  logic [31:0] data;
  logic        valid;
  logic        write_en;
} axi_transaction_t;

`endif
