#!/bin/bash

# Определяем день недели
NUM_DAY=$(date '+%u')

#Определяем принадлежность авторизуемого пользователя группе admin
# Если пользователь включен в группу admin, то AMIN_GROUP=1. В противном случае 0

AMIN_GROUP=$(groups $PAM_USER | grep -c admin)

# Выполняем проверки: Принадлежность группе admin и номеров дней недели

if [[ $ADMIN_GROUP -eq 1 ]] ; then
	exit 0
else
	if [[ $NUM_DAY -gt 5 ]] ; then 
		exit 1
	else
		exit 0
	fi	
fi
