import math

WIDTH = 20
Q_BITS = 12
IMAGE_WIDTH = 8
IMAGE_HEIGHT = 8

def to_q_fixed(val, q_bits):
    fixed = int(round(val * (1 << q_bits)))
    if fixed < 0:
        fixed = (1 << WIDTH) + fixed
    return fixed & ((1 << WIDTH) - 1)

radian = math.radians(45)  # Dereceyi radyana çevir
tan = math.tan(radian)

with open("u_lut.hex", "w") as u_file, open("v_lut.hex", "w") as v_file:

    for x in range(IMAGE_WIDTH):
        u = ((2.0 * ((x + 0.5) / IMAGE_WIDTH)) - 1.0) * tan
        print("u = ", u)
        u_fixed = to_q_fixed(u, Q_BITS)
        u_file.write(f"{u_fixed:04x}\n")
    
    for y in range(IMAGE_HEIGHT):
        v = (1.0 - (2.0 * ((y + 0.5) / IMAGE_HEIGHT))) * tan
        print("v = ", v)
        v_fixed = to_q_fixed(v, Q_BITS)
        v_file.write(f"{v_fixed:04x}\n")