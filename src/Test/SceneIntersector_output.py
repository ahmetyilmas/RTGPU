import numpy as np
import matplotlib.pyplot as plt

# TXT dosyasının yolu
filename = "C:/Users/Ahmet/Desktop/output.txt"

# Görüntü boyutu
WIDTH = 8
HEIGHT = 8

pixels = []
with open(filename, "r") as f:
    for i, line in enumerate(f):
        parts = line.strip().split()
        if len(parts) >= 3:
            try:
                r, g, b = map(int, parts[:3])
                pixels.append([r, g, b])
            except ValueError:
                print(f"Hatalı sayı satırı {i+1}: {line.strip()}")
        else:
            print(f"Geçersiz satır {i+1}: {line.strip()}")

# Satır sayısını kontrol et
if len(pixels) != WIDTH * HEIGHT:
    print(f"UYARI: Piksel sayısı uyuşmuyor! Beklenen: {WIDTH * HEIGHT}, Okunan: {len(pixels)}")

# Bozuksa devam etmeyi engelle
assert len(pixels) == WIDTH * HEIGHT, "Görüntü boyutu ile piksel sayısı uyuşmuyor."

# Görüntü oluştur
image = np.array(pixels, dtype=np.uint8).reshape((HEIGHT, WIDTH, 3))

# Görüntüyü göster
plt.imshow(image)
plt.axis('off')
plt.title("Raytraced Scene")
plt.show()

# Görüntüyü dosyaya kaydet
plt.imsave("scene_output.png", image)
