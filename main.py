import os


def print_directory_structure(root_dir, indent=""):
    # Игнорируем папки, начинающиеся с точки
    if os.path.basename(root_dir).startswith('.'):
        return

    print(indent + os.path.basename(root_dir) + "/")
    indent += "    "

    for item in os.listdir(root_dir):
        item_path = os.path.join(root_dir, item)

        # Игнорируем файлы с расширениями .tmp и .png
        if item.lower().endswith(('.tmp', '.png')):
            continue

        if os.path.isdir(item_path):
            print_directory_structure(item_path, indent)
        else:
            print(indent + item)

if __name__ == "__main__":
    project_path = 'Scenes'  # Укажите путь к вашему проекту
    print_directory_structure(project_path)