#!/bin/bash

# Функция, которая выводит таблицу файловых систем, исключая виртуальные файловые системы и файловые системы в памяти.
function print_filesystem_table {
  echo -e "Device\t\tType\t\tMount Point"
  echo "------------------------------------------------------"
  df -h --output=source,fstype,target | grep -v -E "tmpfs|devtmpfs|proc|sysfs|cgroup|debugfs|securityfs|tracefs|pstore|hugetlbfs|binfmt_misc|configfs|rpc_pipefs|fusectl|fuse.gvfsd-fuse" | awk '{printf "%-16s %-11s %s\n",$1,$2,$3}'
}


function mount_fs {
  # Запрос пути до устройства или файла
  read -p "Введите путь до устройства или файла: " device
  if [ ! -e "$device" ]; then
    echo "Ошибка: указанный файл или устройство не существует"
    return
  fi

  # Запрос каталога монтирования
  read -p "Введите путь до каталога монтирования: " mountpoint
  if [ ! -d "$mountpoint" ]; then
    # Если каталога не существует, создать его
    echo "Каталог монтирования не существует, создаю..."
    mkdir -p "$mountpoint"
  else
    # Если каталог существует, проверить, что он пустой
    if [ "$(ls -A $mountpoint)" ]; then
      echo "Ошибка: каталог монтирования не пустой"
      return
    fi
  fi

  # Монтирование файловой системы
  if [ -b "$device" ]; then
    # Если указано устройство, монтировать его
    sudo mount "$device" "$mountpoint"
  elif [ -f "$device" ]; then
    # Если указан файл, монтировать его в режиме loopback
    sudo mount -o loop "$device" "$mountpoint"
  else
    echo "Ошибка: неподдерживаемый тип файла"
    return
  fi

  echo "Файловая система успешно смонтирована в $mountpoint"
}


# функция вывода списка файловых систем и выбора раздела
function choose_device {
    # получаем список разделов, исключая виртуальные файловые системы и файловые системы в памяти
    devices=$(lsblk -lpno NAME,FSTYPE,MOUNTPOINT | awk '!/loop/ && !/tmpfs/ && !/cgroup/ && !/Filesystem/ {print $0}')

    # выводим пронумерованный список разделов
    echo "Список разделов:"
    echo "$devices" | awk '{print NR".", $0}'

    # запрашиваем у пользователя выбор раздела или ввод пути вручную
    read -p "Введите номер раздела или путь до устройства: " choice

    # проверяем, является ли выбор числом (номером раздела)
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        # извлекаем выбранный раздел из списка
        device=$(echo "$devices" | sed -n "${choice}p" | awk '{print $1}')
    else
        # выбор - это путь до устройства, который мы используем напрямую
        device="$choice"
    fi

    # проверяем, что раздел выбран
    if [ -z "$device" ]; then
        echo "Раздел не выбран"
        return 1
    fi

    # отмонтируем раздел
    umount "$device"
    echo "Файловая система на разделе $device отмонтирована"
}




# Функция вывода меню и выбора примонтированной файловой системы
function select_mount() {
    # Получаем список примонтированных файловых систем и исключаем виртуальные файловые системы и файловые системы в памяти
    mount_list=$(mount | awk '!/^sysfs|^proc|^udev|^tmpfs|^devpts|^securityfs|^cgroup|^pstore|^hugetlbfs|^mqueue|^debugfs|^sunrpc|^rpc_pipefs|^fusectl|^binfmt_misc|^fuseblk/ {print $3}')

    if [ -z "$mount_list" ]; then
        echo "Нет примонтированных файловых систем, которые можно изменить"
        return 1
    fi

    echo "Выберите примонтированную файловую систему:"
    PS3="Введите номер: "
    select mount_point in $mount_list; do
        if [ -n "$mount_point" ]; then
            echo "Выбрана файловая система $mount_point"
            break
        else
            echo "Неверный выбор"
        fi
    done
}

# Функция изменения параметров монтирования
function change_mount() {
    select_mount || return 1

    # Выводим текущие параметры монтирования
    echo "Текущие параметры монтирования:"
    mount | grep "$mount_point"

    # Переводим файловую систему в режим "только чтение"
    echo "Перевести файловую систему в режим 'только чтение' (y/n)?"
    read -r readonly_mode
    if [ "$readonly_mode" = "y" ]; then
        sudo mount -o remount,ro "$mount_point"
    fi

    # Переводим файловую систему в режим "чтение и запись"
    echo "Перевести файловую систему в режим 'чтение и запись' (y/n)?"
    read -r readwrite_mode
    if [ "$readwrite_mode" = "y" ]; then
        sudo mount -o remount,rw "$mount_point"
    fi
}


# Функция, выводящая параметры монтирования выбранной файловой системы
function show_mount_options {
    echo "Список доступных файловых систем:"
    # Выводим список доступных файловых систем, исключая виртуальные и файловые системы в памяти
    filesystems=$(grep -v -E "^(tmpfs|proc|sysfs|devpts|debugfs|cgroup)" /etc/mtab | awk '{print $1}' | sort -u)
    select fs in $filesystems; do
        if [ -n "$fs" ]; then
            options=$(mount | grep "^$fs " | awk '{print $6}')
            echo "Параметры монтирования для $fs:"
            echo "$options"
            break
        else
            echo "Некорректный выбор. Попробуйте ещё раз."
        fi
    done
}





# Функция, которая выводит главное меню.
function show_main_menu {
  echo "Main menu:"
  echo "1. Show filesystem table"
  echo "2. МОнтировать"
  echo "3. отМОнтировать"
  echo "4.Изменить параметры монтирования примонтированной файловой системы"
  echo "5.выводящая параметры монтирования выбранной файловой системы"
  echo "4. Exit"
}

# Переменная, которая хранит выбранный пункт меню.
menu_choice=0

# Основной цикл программы.
while [ "$menu_choice" -ne 2 ]; do
  # Выводим главное меню.
  show_main_menu

  # Читаем выбранный пункт меню.
  read -p "Enter your choice: " menu_choice

  # Выполняем действия в соответствии с выбранным пунктом меню.
  case "$menu_choice" in
    1)
      # Вызываем функцию для вывода таблицы файловых систем.
      print_filesystem_table
      ;;
    2)
      mount_fs
      ;;
    3)
      choose_device
      ;;
    4)
      change_mount
      ;; 
    5)
      show_mount_options
      ;;
    6)
      echo "Exiting..."
      ;;
    *)
      echo "Invalid choice. Please try again."
      ;;
  esac
done
