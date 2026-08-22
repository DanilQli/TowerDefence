import os

import random

# Предметы по ID (1-16)
SUBJECTS = {
    1: "Литература",
    2: "Алгебра",
    3: "Геометрия",
    4: "Статистика и вероятность",
    5: "Информатика",
    6: "Физика",
    7: "Химия",
    8: "Биология",
    9: "История",
    10: "География",
    11: "Обществознание",
    12: "Право",
    13: "Экономика"
}

# Логичные профильные комбинации (направления)
PROFILES = {
    "технический": {
        "основа": [2, 3, 5, 6],  # Алгебра, Геометрия, Информатика, Физика
        "дополнительные": [4, 7]  # Статистика, Химия
    },
    "естественнонаучный": {
        "основа": [7, 8, 6],  # Химия, Биология, Физика
        "дополнительные": [2, 10]  # Алгебра, География
    },
    "гуманитарный": {
        "основа": [9, 11, 12, 1],  # История, Общество, Право, Литература
        "дополнительные": [10]
    },
    "социально-экономический": {
        "основа": [11, 13, 9, 12],  # Общество, Экономика, История, Право
        "дополнительные": [2, 4, 10]  # Алгебра, Статистика, География
    },
    "лингвистический": {
        "основа": [1, 11],  # Литература, Общество
        "дополнительные": [9]  # История
    },
    "IT": {
        "основа": [5, 2, 4],  # Информатика, Алгебра, Статистика
        "дополнительные": [3, 6]  # Геометрия, Физика
    }
}


def generate_smart_choice():
    """Генерирует логичный набор профильных предметов"""
    # Выбираем случайный профиль
    profile_name = random.choice(list(PROFILES.keys()))
    profile = PROFILES[profile_name]

    # Количество предметов (2, 3 или 4)
    k = random.randint(2, 4)

    # Выбираем из основы профиля
    main_count = min(k, len(profile["основа"]))
    chosen = random.sample(profile["основа"], random.randint(max(1, main_count - 1), main_count))

    # Добавляем дополнительные если нужно
    if len(chosen) < k and profile["дополнительные"]:
        extra_needed = k - len(chosen)
        available_extra = [s for s in profile["дополнительные"] if s not in chosen]
        if available_extra:
            extra = random.sample(available_extra, min(extra_needed, len(available_extra)))
            chosen.extend(extra)

    return chosen


def generate_random_choice():
    """Генерирует полностью случайный набор (для 2% учеников)"""
    k = random.randint(2, 4)
    return random.sample(range(1, 17), k)


def generate_choices(start_idx, end_idx, random_percent=2):
    """Генерирует выбор для диапазона учеников"""
    total_students = end_idx - start_idx
    random_count = max(1, int(total_students * random_percent / 100))

    # Индексы учеников с полностью случайным выбором
    random_students = set(random.sample(range(start_idx, end_idx), random_count))

    print(f"-- Всего учеников: {total_students}")
    print(f"-- Случайный выбор (2%): {random_count} учеников")
    print(f"-- Индексы случайных: {sorted(random_students)}")
    print()

    for i in range(start_idx, end_idx):
        student_id = i + 1

        if i in random_students:
            # Полностью случайный выбор (2%)
            choices = generate_random_choice()
            comment = "-- СЛУЧАЙНЫЙ"
        else:
            # Обдуманный выбор (98%)
            choices = generate_smart_choice()

        choices_str = ','.join(map(str, choices))
        print(f"CALL p_set_choices({student_id}, '{choices_str}');")


def print_directory_structure(root_dir, indent=""):
    # Игнорируем папки, начинающиеся с точки
    if os.path.basename(root_dir).startswith('.'):
        return

    print(indent + os.path.basename(root_dir) + "/")
    indent += "    "

    for item in os.listdir(root_dir):
        item_path = os.path.join(root_dir, item)

        # Игнорируем файлы с расширениями .tmp и .png
        if item.lower().endswith(('.css', '.js', '.txt', '.md', '.cache')):
            continue

        if os.path.isdir(item_path):
            print_directory_structure(item_path, indent)
        else:
            print(indent + item)

if __name__ == "__main__":
    """project_path = 'SchoolSchedule'  # Укажите путь к вашему проекту
    print_directory_structure(project_path)
    import os"""

    # Расширения файлов, которые нас интересуют
    TARGET_EXTENSIONS = ['.gd', '.ю']

    # Путь к директории проекта (может быть . — текущая директория)
    PROJECT_DIR = '.'

    # Выходной файл
    OUTPUT_FILE = 'all.txt'

    IGNORE_DIR = 'addons'

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as output_file:
        # Рекурсивный обход всех файлов в проекте
        for root, dirs, files in os.walk(PROJECT_DIR):
            # Модифицируем dirs на месте, чтобы os.walk не заходил в 'addons'
            if IGNORE_DIR in dirs:
                dirs.remove(IGNORE_DIR)

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
    cons = 120
    mn_lvl = 1.07
    mn = 1.07
    m_1 = [[cons],[round(cons * mn, 2)],[round(cons * mn * mn, 2)],
           [round(cons * mn * mn * mn, 2)],[round(cons * mn * mn * mn * mn, 2)],
           [round(cons * mn * mn * mn * mn * mn, 2)],[round(cons * mn * mn * mn * mn * mn * mn, 2)],
           [round(cons * mn * mn * mn * mn * mn * mn * mn, 2)],[round(cons * mn * mn * mn * mn * mn * mn * mn * mn, 2)]
        ,[round(cons * mn * mn * mn * mn * mn * mn * mn * mn * mn, 2)]]
    for i in range(len(m_1)):
        for j in range(9):
            m_1[i].append(round(m_1[i][j] * mn_lvl, 2))
        print(str(i) + ": " + str(m_1[i]) + ",")


    text="""

        """

    names = [line.strip() for line in text.splitlines() if line.strip()]
    result = [(name, 10) for name in names]

    for item in result:
        print(f"({repr(item[0])}, 5),")
    import random

    generate_choices(2100, 2101, random_percent=5)
