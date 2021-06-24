#!/bin/bash

#Проверка pid файла и создание его при запуске
#
if [[ -f /var/run/an-log.pid ]] ; then
        echo "Скрипт уже выполняется. Аварийное завершение !!!"
        exit 1
else
        echo $$ > /var/run/an-log.pid
fi

file_log=access.log
file_rez=rezult.log
file_numline=numline
sendaddress="sarafanov-67@rambler.ru"


# Проверка на наличие файла log используемого для анализа

if [[ ! -f $file_log ]]; then
        echo 'Файл для проведения анализа отсутствует !!!!' > $file_rez
        echo 'Ожидался - ' $file_log >> $file_rez
        mail -s "Результаты анализа log файла nginx" "$sendaddress" < $file_rez
        rm -rf /var/run/an-log.pid
        exit 1
fi



# Проверка на наличие файла с номером строки для продолжения подсчета
if [[ ! -f $file_numline ]]; then
        > $file_numline
        echo 0 > $file_numline
fi


# Удаление пустных строк из файла log

cp $file_log tmp.log; rm -rf $file_log
> $file_log
awk '!/^$/' tmp.log >> $file_log
rm -rf tmp.log

# Считывание значения из файла
num_line=$(cat $file_numline 2>/dev/null);status=$?

# Сколько строк в файле
checkLines=$(wc $file_log | awk '{print $1}')


# Если возвращается пустое значение, т.е. его нет, тогда считаем количество строк и записываем значение в файл
    # Определяем дату и время начала и окончания расчета статистики


# Дата начала и конца
# timebegin=$(awk '{print $4}' $file_log  | sed -n "$(($number+1))"p | cut -c2- )
timebegin=$( awk "NR>$(($num_line+1))" $file_log | awk '{print $4}' | sed -n "$(($number+1))"p | cut -c2- )
timeend=$(tail -n 1 $file_log | awk '{print $4 }' | cut -c2- )

echo 'Период проведения анализа. Начало: '$timebegin' Завершение '$timeend > $file_rez

# Определение количества IP запросов с IP адресов
echo '10 IP адресов с макс. коичеством обращений за указанный период:' >> $file_rez
awk "NR>$(($num_line+1))"  $file_log |  awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10  >> $file_rez

# Y количества адресов
echo '5 http адресов с максимальным количеством обращений за указанный период:' >> $file_rez
awk "NR>$(($num_line+1))"  $file_log | awk '($9 ~ /200/)' | awk '{print $7}' | sort | uniq -c | sort -rn | head -n 5 >> $file_rez

# Количество ответов с кодом 200
echo 'Количество ответов с кодом 200' >> $file_rez
awk "NR>$(($num_line+1))"  $file_log | awk '($9 ~ /200/)' |cut -d '"' -f3 | cut -d ' ' -f2 | sort | uniq -c | sort -rn >> $file_rez

# все ошибки c момента последнего запуска
echo 'Перечень кодов ошибок и их количество за указанный период:' >> $file_rez
awk "NR>$(($num_line+1))"  $file_log | awk '($9 ~ /3/)' |cut -d '"' -f3 | cut -d ' ' -f2 | sort | uniq -c | sort -rn >> $file_rez
awk "NR>$(($num_line+1))"  $file_log | awk '($9 ~ /4/)' |cut -d '"' -f3 | cut -d ' ' -f2 | sort | uniq -c | sort -rn >> $file_rez
awk "NR>$(($num_line+1))"  $file_log | awk '($9 ~ /5/)' |cut -d '"' -f3 | cut -d ' ' -f2 | sort | uniq -c | sort -rn >> $file_rez


# Запись количества строк в файле
echo $checkLines > $file_numline
# Отправка почты
mail -s "Результаты анализа log файла nginx" "$sendaddress" < $file_rez

rm -rf /var/run/an-log.pid
