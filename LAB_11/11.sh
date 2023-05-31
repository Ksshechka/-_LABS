#!/bin/bash

# Функция для изменения существующего порта службы
change_port() {
    read -p "Введите имя службы: " service_name

    # Проверка существования службы в SELinux
    if ! semanage port -l | grep -q "\<${service_name}\>"; then
        echo "Служба '${service_name}' не найдена в SELinux."
        return
    fi

    echo "Доступные порты для службы '${service_name}':"
    semanage port -l | awk -v service="${service_name}" '$1 == service { print $3 }'

    read -p "Выберите порт из списка выше: " old_port
    read -p "Введите новый номер порта: " new_port

    # Изменение порта службы
    semanage port -m -t <тип службы> -p tcp -o ${old_port} -n ${new_port}
    semanage port -m -t <тип службы> -p udp -o ${old_port} -n ${new_port}

    echo "Порт службы '${service_name}' успешно изменен с '${old_port}' на '${new_port}'."
}

# Функция для добавления нового порта службы
add_port() {
    read -p "Введите имя службы: " service_name
    read -p "Введите номер порта: " port_number

    # Добавление нового порта для службы
    semanage port -a -t <тип службы> -p tcp ${port_number}
    semanage port -a -t <тип службы> -p udp ${port_number}

    echo "Новый порт '${port_number}' успешно добавлен для службы '${service_name}'."
}

# Функция для переразметки каталога 
relabel_directory() {
    read -p "Введите путь к каталогу: " directory_path

    # Проверка существования каталога
    if [ ! -d "$directory_path" ]; then
        echo "Каталог '$directory_path' не существует."
        return
    fi

    # Выполнение переразметки каталога
    restorecon -R -v "$directory_path"

    echo "Каталог '$directory_path' успешно заменен."
}

# Функция для запуска полной переразметки файловой системы при перезагрузке
relabel_filesystem() {
    echo "Запуск полной переразметки файловой системы при перезагрузке..."
    touch /.autorelabel
    echo "Перезагрузите систему для завершения переразметки."
}

# Функция для изменения домена файла или каталога (рекурсивно)
change_file_domain() {
    read -e -p "Введите путь к файлу или каталогу: " file_path

    # Проверка существования файла или каталога
    if [ ! -e "$file_path" ]; then
        echo "Файл или каталог '$file_path' не существует."
        return
    fi

    read -p "Введите новый домен: " new_domain

    # Изменение домена файла или каталога
    chcon -R -t "$new_domain" "$file_path"

    echo "Домен для '$file_path' успешно изменен на '$new_domain'."
}

# Функция для вывода списка переключателей с описанием и состоянием
list_toggles() {
    echo "Список переключателей SELinux:"
    semanage boolean -l | awk '{print "Переключатель: "$1"\nОписание: "$3"\nСостояние: "$2"\n"}'
}

# Функция для изменения переключателя
change_toggle() {
    read -p "Введите имя переключателя: " toggle_name

    # Проверка существования переключателя
    if ! semanage boolean -l | awk '{print $1}' | grep -q "\<${toggle_name}\>"; then
        echo "Переключатель '$toggle_name' не найден в SELinux."
        return
    fi

    current_state=$(getsebool "$toggle_name" | awk '{print $3}')

    echo "Текущее состояние переключателя '$toggle_name': $current_state"

    if [[ $current_state == "on" ]]; then
        read -p "Выключить переключатель? (y/n): " disable_choice
        if [[ $disable_choice == "y" ]]; then
            setsebool "$toggle_name" off
            echo "Переключатель '$toggle_name' успешно выключен."
        fi
    elif [[ $current_state == "off" ]]; then
        read -p "Включить переключатель? (y/n): " enable_choice
        if [[ $enable_choice == "y" ]]; then
            setsebool "$toggle_name" on
            echo "Переключатель '$toggle_name' успешно включен."
        fi
    fi
}

# Выбор
while true; do
    echo "Меню выбора:"
    echo "1. Управление портами в SELinux"
    echo "2. Управление файлами в SELinux"
    echo "3. Управление переключателями SELinux"
    read -p "Выберите опцию (1, 2 или 3): " main_choice

    case $main_choice in
        1)
            while true; do
                echo "Управление портами в SELinux:"
                echo "1. Изменить существующий порт службы"
                echo "2. Добавить новый порт для службы"
                read -p "Выберите опцию (1 или 2): " port_choice

                case $port_choice in
                    1)
                        change_port
                        ;;
                    2)
                        add_port
                        ;;
                    *)
                        echo "Неверный выбор. Пожалуйста, выберите 1 или 2."
                        ;;
                esac

                read -p "Хотите продолжить управление портами (y/n)? " continue_ports

                if [[ $continue_ports != "y" ]]; then
                    break
                fi
            done
            ;;
        2)
            while true; do
                echo "Управление файлами в SELinux:"
                echo "1. Переразметка каталога (рекурсивно)"
                echo "2. Запустить полную переразметку файловой системы при перезагрузке"
                echo "3. Изменить домен файла или каталога (рекурсивно)"
                read -p "Выберите опцию (1, 2 или 3): " file_choice

                case $file_choice in
                    1)
                        relabel_directory
                        ;;
                    2)
                        relabel_filesystem
                        ;;
                    3)
                        change_file_domain
                        ;;
                    *)
                        echo "Неверный выбор. Пожалуйста, выберите 1, 2 или 3."
                        ;;
                esac

                read -p "Хотите продолжить управление файлами (y/n)? " continue_files

                if [[ $continue_files != "y" ]]; then
                    break
                fi
            done
            ;;
        3)
            while true; do
                echo "Управление переключателями SELinux:"
                echo "1. Вывести список переключателей с описанием и состоянием"
                echo "2. Изменить переключатель"
                read -p "Выберите опцию (1 или 2): " toggle_choice

                case $toggle_choice in
                    1)
                        list_toggles
                        ;;
                    2)
                        change_toggle
                        ;;
                    *)
                        echo "Неверный выбор. Пожалуйста, выберите 1 или 2."
                        ;;
                esac

                read -p "Хотите продолжить управление переключателями (y/n)? " continue_toggles

                if [[ $continue_toggles != "y" ]]; then
                    break
                fi
            done
            ;;
        *)
            echo "Неверный выбор. Пожалуйста, выберите 1, 2 или 3."
            ;;
    esac

    read -p "Хотите вернуться в главное меню (y/n)? " continue_main

    if [[ $continue_main != "y" ]]; then
        break
    fi
done
