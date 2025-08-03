import os


"""def print_directory_structure(root_dir, indent=""):
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
            print(indent + item)"""

if __name__ == "__main__":
    """project_path = 'Scenes'  # Укажите путь к вашему проекту
    print_directory_structure(project_path)"""
    import os

    # Расширения файлов, которые нас интересуют
    TARGET_EXTENSIONS = ['.gd', '.tscn']

    # Путь к директории проекта (может быть . — текущая директория)
    PROJECT_DIR = '.'

    # Выходной файл
    OUTPUT_FILE = 'all.txt'

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as output_file:
        # Рекурсивный обход всех файлов в проекте
        for root, dirs, files in os.walk(PROJECT_DIR):
            for file in files:
                if any(file.endswith(ext) for ext in TARGET_EXTENSIONS):
                    file_path = os.path.join(root, file)
                    # Нормализуем путь для компактного вывода
                    normalized_path = os.path.relpath(file_path, PROJECT_DIR)

                    try:
                        with open(file_path, 'r', encoding='utf-8') as source_file:
                            content = source_file.read()

                        # Записываем в all.txt
                        output_file.write(f"# {normalized_path}\n")
                        output_file.write(content)
                        output_file.write("\n\n")  # Разделитель между файлами
                    except Exception as e:
                        print(f"⚠️ Не удалось прочитать файл: {normalized_path} ({e})")                 
    cons = 50.0
    mn_lvl = 1.16
    mn = 1.11
    m_1 = [[cons],[round(cons * mn, 2)],[round(cons * mn * mn, 2)],
           [round(cons * mn * mn * mn, 2)],[round(cons * mn * mn * mn * mn, 2)],
           [round(cons * mn * mn * mn * mn * mn, 2)],[round(cons * mn * mn * mn * mn * mn * mn, 2)],
           [round(cons * mn * mn * mn * mn * mn * mn * mn, 2)],[round(cons * mn * mn * mn * mn * mn * mn * mn * mn, 2)]
        ,[round(cons * mn * mn * mn * mn * mn * mn * mn * mn * mn, 2)]]
    for i in range(len(m_1)):
        for j in range(9):
            m_1[i].append(round(m_1[i][j] * mn_lvl, 2))
        print(str(i) + ": " + str(m_1[i]) + ",")
