#!/bin/bash
#proc=$1
#clk_1=$(getconf CLK_TCK)
fmt="%-20s%-8s%-10s%-10s%-10s%-10s%-10s%-50s\n"
printf "$fmt" USER PID VSZ RSS TTY STAT TIME COMMAND
    for pid in `ls /proc/ | egrep "^[0-9]" | sort -n`
    do
        if [[ -f /proc/$pid/status ]]
        then
            PID=$pid
            COMM=$(tr -d '\0' < /proc/$pid/cmdline)
            if [[ -z "$COMM" ]]
                then
                COMM="[`awk '/Name/{print $2}' /proc/$pid/status`]"
                else
                COMM=$(tr -d '\0' < /proc/$pid/cmdline)
            fi
            COMM="${COMM:0:80}"
            
            USER01=`awk '/Uid/{print $2}' /proc/$pid/status`
                     
            
            VSZ=`cat /proc/$pid/status | awk '/VmSize/{print $2}'`
            
            if [[ $VSZ == "null" ]] || [[ -z "$VSZ" ]]
            then
                VSZ=0
            fi
            
            RSS=`cat /proc/$pid/status | awk '/VmRSS/{print $2}'`
            
            if [[ $RSS == "null" ]] || [[ -z "$RSS" ]]
            then
                RSS=0
            fi
            
            if [ -z "$(ls -A /proc/$pid/fd)" ]; then
                TTY1="?"
            else
                TTY1=`sudo ls -l /proc/$pid/fd/0 | head -n2 | tail -n1 | sed 's%.*/dev/%%'`
            fi
            
            if [[ $TTY1 == "total 0" ]] || [[ $TTY1 == "null" ]] || [[ $TTY1 == *"socket"* ]] || [[ $TTY1 == *"pipe"* ]]; then
                TTY="?"
            else
                TTY=$TTY1
            fi
    
            STAT=`cat /proc/$pid/stat | awk '{print $3}'`
            USERTIME=`cat /proc/$pid/stat | awk '{print $14}'`
            SYSTIME=`cat /proc/$pid/stat | awk '{print $17}'`
            TIME=`echo $USERTIME $SYSTIME | awk -v val=$(getconf CLK_TCK) '{print ($1+$2)/val}'`
                                 
            if [[ $USER01 -eq 0 ]] || [[ -z $USER01 ]]
            then
                USER='root'
            else
                if [[ $USER01 -eq 65534 ]]
                then
                    USER='nfsnobody'
                else 
                    USER=$(grep $USER01 /etc/passwd | cut -d':' -f1,2,3 | awk -F ":" -v x=$USER01 '$3==x {print $1}')	   
                fi   
            
            
            fi
            
            printf "$fmt" $USER $PID $VSZ $RSS $TTY $STAT $TIME "$COMM"
        fi
    done
    
    
