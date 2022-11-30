#!/bin/bash
1.11

echo "Каталоги:"
ls -l
echo "Обычные файлы:"
ls -la
echo "Символьные ссылки:"
ls -i
echo "Символьные устройства:"
ls -l | grep ^c
echo "Блочные устройства:"
ls -l | grep ^b

