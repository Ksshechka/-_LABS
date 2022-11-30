#!/bin/bash
1.8
echo "Процессов пользователя"
whoami 
ps  -u | wc -l

echo "Процессов пользователя root:"
ps  -u root | wc -l


