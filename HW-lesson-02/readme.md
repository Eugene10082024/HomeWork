## ДЗ к Занятию 2.

## Работа с mdadm - что сделать.

1. добавить в Vagrantfile еще дисков сломать/починить raid собрать R0/R5/R10 на выбор.

Прописать собранный рейд в конф, чтобы рейд собирался при загрузке создать GPT раздел и 5 партиций.

В качестве проверки принимаются - измененный Vagrantfile, скрипт для создания рейда, конф для автосборки рейда при загрузке

2. доп. задание - Vagrantfile, который сразу собирает систему с подключенным рейдом

### Дополнительная информация.

В каталоге создано 2 подкатлога в которых размещены vagranfile

папка VM-01 - содержит vagranfile для автоматисеского сбора RAID10 из 4 дисков

папка VM-02 - содержит vagranfile для автоматисеского сбора RAID10 из 4 дисков и автоматического создания 5 разделов

## Выполнение п.1.

### 1. Создание RAID 10

Для выполнения данного пункта ДЗ был взят за основу Vagrant файл для развертывания CentOS 7 по адресу -  https://github.com/erlong15/otus-linux.

В процессе развертывания ВМ появились 2 cообщения:

Сообщение 1
        [test-otus] No Virtualbox Guest Additions installation found.

Сообщение 2        
        
        The following SSH command responded with a non-zero exit status.
        
        Vagrant assumes that this means the command failed!

        umount /mnt

        Stdout from the command:

        Stderr from the command:

        umount: /mnt: not mounted
        

Для устранения данных сообщений и нормальной работы была выполнена установка доп. пакетов  перезагрузка конфигурации vagrantfile.

        vagrant ssh

sudo yum install dkms binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel kernel.x86_64 -y

        vagrant reload

В итоге был подключен VBoxGuestAdditions.iso и выполнены все необходимые настройки.

Далее выполняем ручную настройку RAID 10.

1.1. Проверяем наличие необходимого количества дисков для создания программного RAID 10 (минимум 4)

  [vagrant@localhost ~]$ lsblk
  
    NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT

    sda      8:0    0   1G  0 disk 

    sdb      8:16   0   1G  0 disk 

    sdc      8:32   0   1G  0 disk 

    sdd      8:48   0   1G  0 disk 

    sde      8:64   0  40G  0 disk 

    `-sde1   8:65   0  40G  0 part /


1.2. Устанавливаем необходимые пакеты для создания RAID 10

    sudo yum install mdadm smartmontools hdparm gdisk -y

1.3. Обнуляем суперблоки на дисках, которые мы будем использовать для построения RAID 10

    sudo mdadm --zero-superblock --force /dev/sd{a,b,c,d}
    
    mdadm: Unrecognised md component device - /dev/sda
    
    mdadm: Unrecognised md component device - /dev/sdb
    
    mdadm: Unrecognised md component device - /dev/sdc
    
    mdadm: Unrecognised md component device - /dev/sdd

Это означает, что диски не использовались для RAID

1.4. Удаляем старые метаданные и подпись на дисках:

    sudo wipefs --all --force /dev/sd{a,b,c,d}
    
1.5. Собираем RAID10

    sudo mdadm --create --verbose /dev/md0 -l 10 -n 4 /dev/sd{a,b,c,d}
    
    mdadm: layout defaults to n2
    
    mdadm: layout defaults to n2
    
    mdadm: chunk size defaults to 512K
    
    mdadm: size set to 1046528K
    
    mdadm: Defaulting to version 1.2 metadata
    
    mdadm: array /dev/md0 started.

1.6. Выполняем команду lsblk

            NAME   MAJ:MIN RM SIZE RO TYPE   MOUNTPOINT
        sda      8:0    0   1G  0 disk   
        
        └─md0    9:0    0   2G  0 raid10 
        
        sdb      8:16   0   1G  0 disk   
        
        └─md0    9:0    0   2G  0 raid10 
        
        sdc      8:32   0   1G  0 disk   
        
        └─md0    9:0    0   2G  0 raid10 
        
        sdd      8:48   0   1G  0 disk   
        
        └─md0    9:0    0   2G  0 raid10 
        
        sde      8:64   0  40G  0 disk   
        
        └─sde1   8:65   0  40G  0 part   /


1.7. Создаем файл mdadm.conf. В нем находится информация о RAID-массивах и компонентах, которые в них входят

    sudo mkdir /etc/mdadm

    sudo echo "DEVICE partitions" > /etc/mdadm/mdadm.conf

    sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

Вывод файла mdadm.conf:

    DEVICE partitions
    
    ARRAY /dev/md0 level=raid10 num-devices=4 metadata=1.2 name=otuslinux:0 UUID=0094093f:7bfa427f:ef04b2f5:b8ce5c71

   
1.8. Создаем файловую систему для массива

    sudo mkfs.ext4 /dev/md0
    
1.9. Примонтируем  RAID к /mnt

    sudo mount /dev/md0 /mnt
    
1.10.  Чтобы данный RAID также монтировался при загрузке системы, добавляем в fstab строку

    /dev/md0        /mnt    ext4    defaults    1 2
    
1.11. Получаем информацию по RAID

    cat /proc/mdstat
    
    Personalities : [raid10] 
    
    md0 : active raid10 sdd[3] sdc[2] sdb[1] sda[0]
    
        2093056 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
                
    unused devices: <none>


### 2. Сломать/починить RAID

2.1. Ломаем искуственно обо из блочных устройств входящих в RAID10 (sdd)

    sudo mdadm /dev/md0 --fail /dev/sdd
    
        mdadm: set /dev/sdd faulty in /dev/md0

2.2. Проверяем что с RAID

    [root@otuslinux ~]# cat /proc/mdstat 
    
    Personalities : [raid10] 
    
    md0 : active raid10 sdd[3](F) sdc[2] sdb[1] sda[0]
    
        2093056 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]
        
    unused devices: <none>
    
Диск sdd - Fail
    
2.3. Удалим диск sdd из RAID

    sudo mdadm /dev/md0 --remove /dev/sdd
    
2.4. Проверяем

        cat /proc/mdstat 
   
        Personalities : [raid10] 
        md0 : active raid10 sdc[2] sdb[1] sda[0]
        2093056 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]
        unused devices: <none>
        
Теперь у нас 3 диска в RAID 

2.5. Вернем диск sdd в массив RAID 10

        sudo mdadm /dev/md0 --add /dev/sdd
        
2.6. Проверяем

    cat /proc/mdstat
    
    Personalities : [raid10] 
    
    md0 : active raid10 sdd[4] sdc[2] sdb[1] sda[0]
    
        2093056 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]
        
        [=======>.............]  recovery = 37.9% (398080/1046528) finish=0.1min speed=99520K/sec
        
    unused devices: <none>

### 3. создание GPT раздела и 5 партиций

3.1. Создаем таблицу gpt на нстройстве /dev/md0

    sudo parted /dev/md0 -s mklabel gpt

3.2. Создаем 5 разделов одинакового размера

    parted /dev/md0 -s mkpart primary ext4 0% 20%

    parted /dev/md0 -s mkpart primary ext4 20% 40%
    
    parted /dev/md0 -s mkpart primary ext4 40% 60%
    
    parted /dev/md0 -s mkpart primary ext4 60% 80%
    
    parted /dev/md0 -s mkpart primary ext4 80% 100%

3.3. Форматируем созданные 5 разделов ext4
    
    sudo for i in $(seq 1 5); do mkfs.ext4 /dev/md0p$i; done
    
3.4. Создаем точки монтировния для 5 разделов
    
    sudo mkdir /mnt/disk-{1,2,3,4,5}
    
3.5. Монтируем 5 разделов к созданным точкам монтирования

    sudo for i in $(seq 1 5); do mount /dev/md0p$i /mnt/disk-$i; done
    
3.6. проверяем

        [root@otuslinux ~]# df -h
        
        Filesystem      Size  Used Avail Use% Mounted on
        
        devtmpfs        489M     0  489M   0% /dev
        
        tmpfs           496M     0  496M   0% /dev/shm
        
        tmpfs           496M  6,8M  489M   2% /run
        
        tmpfs           496M     0  496M   0% /sys/fs/cgroup
        
        /dev/sde1        40G  7,6G   33G  19% /
        
        tmpfs           100M     0  100M   0% /run/user/1000
        
        tmpfs           100M     0  100M   0% /run/user/0
        
        /dev/md0p1      388M  2,3M  361M   1% /mnt/disk-1
        
        /dev/md0p2      389M  2,3M  362M   1% /mnt/disk-2
        
        /dev/md0p3      388M  2,3M  361M   1% /mnt/disk-3
        
        /dev/md0p4      389M  2,3M  362M   1% /mnt/disk-4
        
        /dev/md0p5      388M  2,3M  361M   1% /mnt/disk-5

3.7. Для автомонтрирования разделов при загрузке ОС добавляем записи в /etc/fstab
    
    sudo for i in $(seq 1 5); do echo "/dev/md0p$i        /mnt/disk-$i    ext4    defaults    1 2">>/etc/fstab; done









    
        
