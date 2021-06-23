#!/bin/bash
#Проверка pid файла и создание его при запуске
#

if [[ -f /var/run/an-log.pid ]] ; then
    echo "Скрипт уже выполняется. Аварийное завершение !!!"
    exit 1
else
    echo $$ > /var/run/an-log.pid
fi

#if ( set -o noclobber; echo "$$">/var/run/an-log.pid ) 2>/dev/null; then trap "rm -f "$lockfile";exit $?" INT TERM EXIT



# Задание переменных файлов
file_log=access.log
file_rez=rezult.log
file_numline=numline


# Удаление пустных строк из файла log
cp $file_log tmp.log; rm -rf $file_log
> $file_log
awk '!/^$/' tmp.log >> $file_log
rm -rf tmp.log

# Считывание значения из файла
num_line=$(cat $file_numline 2>/dev/null);status=$?

# Сколько строк в файле
checkLines=$(wc $file_log | awk '{print $1}')

# Определяем дату и время начала и окончания расчета статистики
# Дата начала и конца
timebegin=$( awk "NR>$(($num_line+1))" $file_log | awk '{print $4}' | sed -n "$(($number+1))"p | cut -c2- )
timeend=$(tail -n 1 $file_log | awk '{print $4 }' | cut -c2- )

echo 'Период проведения анализа. Начало: '$timebegin' Завершение '$timeend > $file_rez

# Определение количества IP запросов с IP адресов
echo '10 IP адресов с макс. коичеством обращений за указанный период:' >> $file_rez
awk "NR>$(($num_line+1))" $file_log | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10 >> $file_rez

# Y количества адресов
echo '5 http адресов с максимальным количеством обращений за указанный период:' >> $file_rez
awk "NR>$(($num_line+1))" $file_log | awk '($9 ~ /200/)' | awk '{print $7}' | sort | uniq -c | sort -rn | head -n 5 >> $file_rez

# все ошибки c момента последнего запуска
echo 'Перечень кодов и их количество за указанный период:' >> $file_rez
awk "NR>$(($num_lime+1))" $file_log | cut -d '"' -f3 | cut -d ' ' -f2 | sort | uniq -c | sort -rn >> $file_rez

# Запись количества строк в файле
echo $checkLines > $file_numline

# Отправка почты
cat $file_rez | mail -s "Анализ access.log за последний час" sarafanov67@rambler.ru

# Удаление an-log.pid
rm -rf /var/run/an-log.pid
#rm -rf $file_rez
#trap - INT TERM EXIT
