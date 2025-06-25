from PIL import Image
import os

def split_image(input_path, rows, cols, output_folder):
    # Открываем изображение
    image = Image.open(f"{output_folder}/{input_path}")
    img_width, img_height = image.size

    # Размеры одного блока
    tile_width = img_width // cols
    tile_height = img_height // rows

    count = 0
    for row in range(rows):
        for col in range(cols):
            left = col * tile_width
            upper = row * tile_height
            right = left + tile_width
            lower = upper + tile_height

            cropped_image = image.crop((left, upper, right, lower))
            output_path = os.path.join(output_folder, f"out_{input_path[:-4]}_{row}_{col}.png")
            cropped_image.save(output_path)
            count += 1

    print(f"✅ Completed: {count} tiles saved to '{output_folder}'.")

# Пример использования
split_image("Fishes_2_32x32.png", rows=1, cols=14, output_folder="21")