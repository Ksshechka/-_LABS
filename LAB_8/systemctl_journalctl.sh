#!bin/bash/
#___________Поиск системных служб:____________
ser_name(){
	read -p "Введите часть имени или имя службы: " service_name

	if [ -z $service_name ]; then
		echo "Вы ничего не ввели :("
		echo "Попробуте еще раз, думаю у Вас получится!"
		exit 1
	fi

	output=$(systemctl list-units -all | grep "$service_name")

	if [ -z "$output" ]; then
		echo "Службы с именем $service_name не найдены :("
		exit 1
	fi

	echo "$output"
	echo ""
	#____________Вывод списка процессов:____________
	read -p "Хотите вывести список процессов и связанных с ними systemd служб?(y/n)" answer

	if [ "$answer" == "y" ]; then
	process_list=$(systemctl list-units --type=service | grep running | awk '{print $1}')

		for process in $process_list
		do
			echo "Процесс: $process"
			echo "Cистемная служба: $(systemctl show -p FragmentPath $process.service | sed 's/FragmentPath//') "/n""
			echo "__________________"
		done
	fi
}

#"_____________Управление службами:___________"
serv(){
	# Получить список доступных служб и вывести их на экран с номерами
	services=$(systemctl list-unit-files --type=service --no-pager --no-legend | awk '{print $1}')
	echo "Доступные службы:"
	echo "$services" | cat -n

	# Запросить у пользователя номер службы
	read -p "Введите номер службы, над которой хотите сделать действие: " service_num

	# Получить имя выбранной службы по её номеру
	service_name=$(echo "$services" | sed "${service_num}q;d")

	# Вывести действия, которые можно выполнить с выбранной службой
	echo "Выбранная служба: $service_name"
	echo "Выберите действие:"
	select action in "Включить службу" "Отключить службу" "Запустить/перезапустить службу" "Остановить службу" "Вывести содержимое юнита службы" "Отредактировать юнит службы" "Выход"; do
	  case $action in
	    "Включить службу")
	      sudo systemctl enable "$service_name"
	      sudo systemctl start "$service_name"
	      echo "Служба включена"
	      break
	      ;;
	    "Отключить службу")
	      sudo systemctl disable "$service_name"
	      echo "Служба отключена"
	      break
	      ;;
	    "Запустить/перезапустить службу")
	      sudo systemctl restart "$service_name"
	      echo "Служба запущена/перезапущена"
	      break
	      ;;
	    "Остановить службу")
	      sudo systemctl stop "$service_name"
	      echo "Служба остановлена"
	      break
	      ;;
	    "Вывести содержимое юнита службы")
	      sudo systemctl cat "$service_name"
	      break
	      ;;
	    "Отредактировать юнит службы")
	      sudo systemctl edit "$service_name"
	      break
	      ;;
	    "Выход")
	      exit
	      ;;
	    *)
	      echo "Неверный выбор :( Попробуйте еще раз!"
	      ;;
	  esac
	done
}

echo "Выберите действие:"
	select options in "Поиск системных служб" "Управление службами" "Выход"; do
	case $options in
	"Поиск системных служб")
		ser_name
	      break
	      ;;
	"Управление службами")
		serv
	      break
	      ;;
 	"Выход")
	      exit
	      ;;
	    *)
	      echo "Неверный выбор :( Попробуйте еще раз!"
	      ;;
	  esac
	done

