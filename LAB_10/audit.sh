#!/bin/bash

# Функция для выполнения первого скрипта
run_script1() {
  echo "Пример типовых событий аудита:"
  echo "1. AVC (действие SELinux)"
  echo "2. USER_AUTH (аутентификация пользователя)"
  echo "3. CRYPTO_KEY_USER (использование ключей шифрования пользователем)"

  read -p "Введите тип события (например, AVC, USER_AUTH, CRYPTO_KEY_USER): " event_type

  read -p "Введите имя пользователя (оставьте пустым для всех пользователей): " username

  audit_log=$(ausearch -m $event_type -ui $username -i --raw)

  if [ -z "$audit_log" ]; then
    echo "Событий аудита с заданными параметрами не найдено."
  else
    echo "Результаты поиска:"
    echo "$audit_log"
  fi
}

# Функция для выполнения второго скрипта
run_script2() {
  generate_login_report() {
    echo "Отчет о входе пользователей в систему за последний $1:"
    aureport --failed --success --start "$1 ago" --end "now" --login
  }

  generate_violation_report() {
    echo "Отчет о нарушениях за последний $1:"
    aureport --failed --start "$1 ago" --end "now"
  }

  generate_report_for_period() {
    case $1 in
      "day")
        generate_login_report "1 day"
        generate_violation_report "1 day"
        ;;
      "week")
        generate_login_report "1 week"
        generate_violation_report "1 week"
        ;;
      "month")
        generate_login_report "1 month"
        generate_violation_report "1 month"
        ;;
      "year")
        generate_login_report "1 year"
        generate_violation_report "1 year"
        ;;
      *)
        echo "Неверно указан период. Доступные периоды: day, week, month, year."
        ;;
    esac
  }

  read -p "Выберите период для генерации отчетов (day, week, month, year): " period
  generate_report_for_period "$period"
}

# Функция для выполнения третьего скрипта
run_script3() {
  add_watch() {
    path=$1
    auditctl -w "$path" -p wa
    echo "Добавлено наблюдение за $path"
  }

  remove_watch() {
    path=$1
    auditctl -W "$path"
    echo "Удалено наблюдение за $path"
  }

  report_watch() {
    path=$1
    echo "Отчет о наблюдении за $path:"
    ausearch -k watch_file -i --raw | grep "$path"
  }

  print_menu() {
    echo "Выберите действие:"
    echo "1. Добавить каталог или файл в список наблюдения"
    echo "2. Удалить каталог из списка наблюдения"
    echo "3. Вывести отчет по наблюдению за каталогом"
    echo "0. Выход"
  }

  while true; do
    print_menu
    read -p "Введите номер действия: " choice

    case $choice in
      1)
        read -p "Введите путь к каталогу или файлу: " watch_path
        add_watch "$watch_path"
        ;;
      2)
        read -p "Введите путь к каталогу: " watch_path
        remove_watch "$watch_path"
        ;;
      3)
        read -p "Введите путь к каталогу: " watch_path
        report_watch "$watch_path"
        ;;
      0)
        echo "Выход"
        exit 0
        ;;
      *)
        echo "Неверно указан номер действия."
        ;;
    esac

    echo
  done
}

# Вывод меню выбора скрипта
print_menu() {
  echo "Выберите скрипт для выполнения:"
  echo "1. Поиск событий аудита"
  echo "2. Генерация отчетов аудита"
  echo "3. Настройка подсистемы аудита для наблюдения за файлами"
  echo "0. Выход"
}

while true; do
  print_menu
  read -p "Введите номер скрипта: " choice

  case $choice in
    1)
      run_script1
      ;;
    2)
      run_script2
      ;;
    3)
      run_script3
      ;;
    0)
      echo "Выход"
      exit 0
      ;;
    *)
      echo "Неверно указан номер скрипта."
      ;;
  esac

  echo
done
