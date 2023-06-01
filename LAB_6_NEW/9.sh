#!/bin/bash
echo "ПРЕДУПРЕЖДЕНИЕ! Скрипт выполнять только с правами root"
echo "Выберите действие из списка: "
echo ""
table(){
	df -Th -x procfs -x tmfs -x devtmpfs -x sysfs
}
mountfs(){
	ls /dev
	# Запрос пути до устройства или файла
	read -p "Введите устройство или путь к файлу: " device_file

	# Проверка на существование файла или устройства
	if [ ! -e $device_file ]; then
	  echo "Файл или устройство не найдены :("
	  exit 1
	fi

	# Запрос каталога монтирования
	read -p "Введите путь к каталогу монтирования: " mount_dir

	# Создание каталога монтирования, если он не существует
	if [ ! -d $mount_dir ]; then
	  mkdir $mount_dir
	fi

	# Проверка, что каталог монтирования пустой
	if [ "$(ls -A $mount_dir)" ]; then
	  echo "Каталог монтирования не пустой"
	  exit 1
	fi

	# Монтирование файловой системы
	if [ -b $device_file ]; then
	  # Если устройство блочное, то монтируем его напрямую
	  mount $device_file $mount_dir
	else
	  # Если указан файл, то монтируем в режиме loopback
	  mount -o loop $device_file $mount_dir
	fi

	# Проверка успешного монтирования
	if [ $? -eq 0 ]; then
	  echo "Успешное монтирование!"
	else
	  echo "Попытка монтирования не удалась. Попробуйте ещё раз. "
	fi
}


unmountfs(){
	# Cписок доступных разделов 
	PS3="Выберите раздел для отмонтирования или введите путь: "
	options=($(find /dev -maxdepth 1 -type b -not -name 'loop*' -not -name 'ram*' -not -name 'dm-*' -printf "%f\n"))
	select opt in "${options[@]}" "Ввести путь"; do
	    case $opt in
		"Ввести путь")
		    read -p "Введите путь до раздела: " device
		    break
		    ;;
		*)
		    device="/dev/$opt"
		    break
		    ;;
	    esac
	done

	# Проверяем, примонтирован ли выбранный раздел
	if ! grep -qs "^$device " /proc/mounts; then
	    echo "Раздел $device не примонтирован"
	    exit 1
	fi

	# Отмонтируем выбранный раздел
	sudo umount $device
	echo "Раздел $device отмонтирован"
}

changepar(){
	# Cписок доступных файловых систеv
	filesystems=$(mount | grep -v "type tmpfs" | grep -v "type proc" | grep -v "type sysfs" | grep -v "type devpts" | grep -v "type debugfs" | grep -v "type securityfs" | grep -v "type cgroup" | grep -v "type pstore" | grep -v "type hugetlbfs" | grep -v "type mqueue" | awk '{print $1}')

	echo "Доступные файловые системы:"
	echo "$filesystems"

	# Выбор системы
	echo "Введите номер файла системы или путь до нее:"
	read choice

	# Проверяем, является ли ввод путем до файловой системы
	if [[ $choice == /dev/* ]]; then
	    filesystem=$choice
	else
	    # Получаем имя файла системы по выбору пользователя
	    filesystem=$(echo "$filesystems" | sed -n "${choice}p")
	fi

	# Проверяем, что файловая система была выбрана
	if [[ -z $filesystem ]]; then
	    echo "Файловая система не выбрана."
	    exit 1
	fi

	# Предлагаем выбор между режимами "только чтение" и "чтение и запись"
	echo "Выберите режим монтирования:"
	echo "1 - Только чтение"
	echo "2 - Чтение и запись"
	read mode_choice

	case $mode_choice in
	    1)
		mount -o remount,ro $filesystem
		echo "Файловая система переведена в режим только чтения."
		;;
	    2)
		mount -o remount,rw $filesystem
		echo "Файловая система переведена в режим чтения и записи."
		;;
	    *)
		echo "Некорректный выбор."
		exit 1
		;;
	esac

	exit 0
}

displaypar(){

	# Список примонтированных файловых систем
	filesystems=$(mount | grep -v "type tmpfs" | grep -v "type proc" | grep -v "type sysfs" | grep -v "type devpts" | grep -v "type debugfs" | grep -v "type securityfs" | grep -v "type cgroup" | grep -v "type pstore" | grep -v "type hugetlbfs" | grep -v "type mqueue" | awk '{print $1}')

	# вывод списка доступных файловых систем
	echo "Доступные файловые системы:"
	echo "$filesystems"

	# запрос выбора файла
	read -p "Введите примонтированную файловую систему: " selected_fs

	# проверка выбранной файловой системы и вывод параметров монтирования
	if echo "$filesystems" | grep -q "$selected_fs"; then
	    mount | grep "$selected_fs"
	else
	    echo "Ошибка: выбранная файловая система не найдена."
	fi
}

sinfo(){
	# Выводим список и предоставляем выбор
	filesystem=$(lsblk -f | grep ext* | awk '{print $1}')
	echo "Выберите файловую систему:"
	select fs in $filesystem
	do
	    if [[ -n "$fs" ]]; then
		break
	    fi
	done

	# Выводим детальную информацию о выбранной файловой системе
	echo "Детальная информация о файловой системе $fs:"
	tune2fs -l /dev/$fs
}


PS3='>'
options=( "Вывести таблицу файловых систем" "Монтировать файловую систему" "Отмонтировать файловую систему" "Изменить параметры монтирования примонтированной файловой системы" "Вывести параметры монтирования примонтированной файловой системы" "Вывести детальную информацию о файловой системе ext*" "Выход") 
while true
do
	select opt in "${options[@]}"
	do
	case $opt in
			
		"Вывести таблицу файловых систем")
			table
			break;;
		"Монтировать файловую систему")
			mountfs
			break;;
		"Отмонтировать файловую систему")
			unmountfs
			
			break;;
		"Изменить параметры монтирования примонтированной файловой системы")
			changepar
			
			break;;
		"Вывести параметры монтирования примонтированной файловой системы")
			displaypar
			
			break;;
		"Вывести детальную информацию о файловой системе ext*")
			sinfo
			
			break;;
		"Выход") exit;;
	*) echo "Нет такой опции";;
	esac

done
done
