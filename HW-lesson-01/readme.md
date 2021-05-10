## ДЗ к Занятию 1

В материалах к занятию есть методичка, в которой описана процедура обновления ядра из репозитория. По данной методичке требуется выполнить необходимые действия. Полученный в ходе выполнения ДЗ Vagrantfile должен быть залит в ваш репозиторий. Для проверки ДЗ необходимо прислать ссылку на него. Для выполнения ДЗ со * и ** вам потребуется сборка ядра и модулей из исходников.
Выполнение основной части ДЗ
### 1. Предварительные действия

1.1. Cоздал учетную запись на GitHub (https://github.com/).

1.2. Выполнил fork репозитория manual_kernel_update.

1.3. Скачал на локальный ПК файл Vagrantfile

1.4. Развернул ВМ с помощью команды vagrant up

### 2. Обновление ядра на ВМ

2.1. Подключился к BM командой vagrant ssh

2.2. Определил текущее установленное ядро.

[vagrant@kernel-update ~]$ 

    uname -a

    Linux kernel-update 3.10.0-1127.el7.x86_64 #1 SMP Tue Mar 31 23:36:51 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux

[vagrant@kernel-update ~]$ 
    
    uname -r

    3.10.0-1127.el7.x86_64

Установлено ядро - 3.10.0-1127.el7.x86_64

2.3. Для установки крайнего рабочего ядра необходимо подключить репозиторий - elrepo-release. Выполняю установку репозитория.

[vagrant@kernel-update ~]$ 

    sudo yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm

Installed:

    elrepo-release.noarch 0:7.0-5.el7.elrepo

Complete!

2.4. Выполняю установку крайнего ядра.

 [vagrant@kernel-update ~]$ 
 
    sudo yum --enablerepo elrepo-kernel install kernel-ml -y

 Installed:

    kernel-ml.x86_64 0:5.12.0-1.el7.elrepo

 Complete!

2.5. Выполнению обновление загрузчика grub [vagrant@kernel-update ~]$

    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

2.6. Задаю загрузку по умолчанию с новым ядром [vagrant@kernel-update ~]$

    sudo grub2-set-default 0

2.7. Перегружаем ВМ [vagrant@kernel-update ~]$

    reboot

2.8. Проверяем какое ядро загрузилось:

    C:\Virtual_Box\files_vagrant\VM_6>vagrant ssh

Last login: Thu Apr 29 09:20:08 2021 from 10.0.2.2

[vagrant@kernel-update ~]$

    uname -r

    5.12.0-1.el7.elrepo.x86_64

### 3. Создание образа системы с помощью packer

3.1. Запусакаем создание образа и получаем ошибку.

    C:\03\Lesson_01\manual\manual_kernel_update-master\packer>packer build centos.json

Error: Failed to prepare build: "centos-7.9"

1 error occurred:

Deprecated configuration key: 'iso_checksum_type'. Please call packer fix

3.2. Выполняю packer fix

    C:\03\Lesson_01\manual\manual_kernel_update-master\packer>packer fix centos.json  > centos-new.json

3.3. Запускаем повторно создание образа.

    C:\03-Обучение\Lesson_01\manual\manual_kernel_update-master\packer>packer build centos-new.json

centos-7.9: Creating virtual machine...

Build 'centos-7.9' finished after 19 minutes 43 seconds.

Wait completed after 19 minutes 43 seconds

Builds finished. The artifacts of successful builds are:

centos-7.7: 'virtualbox' provider box: centos-7.7.1908-kernel-5-x86_64-Minimal.box

3.4. Добавляем созданный образ в локальный репозиторий vagrant

    root@pc-01:/mnt/disk-data/data/0-HW/HW-01/manual_kernel_update-master/packer# vagrant box add --name centos-7-5 centos-7.7.1908-kernel-5-x86_64-Minimal.box

    box: Box file was not detected as metadata. Adding it directly...

    box: Adding box 'centos-7-5' (v0) for provider:

    box: Unpacking necessary files from: file:///mnt/disk-data/data/0-HW/HW-01/manual_kernel_update-master/packer/centos-7.7.1908-kernel-5-x86_64-Minimal.box

    box: Successfully added box 'centos-7-5' (v0) for 'virtualbox'!

3.6. Выполняем проверку: 

    C:\Users\a.sarafanov>vagrant box list

    CentOS-7-5    (virtualbox, 0)

    centos/7      (virtualbox, 2004.01)

3.7. Создаем конфигурационный файл vagrant

    root@pc-01:/mnt/disk-data/data/0-HW/HW-01/VM-02# vagrant init centos-7-5

    A Vagrantfile has been placed in this directory. You are now

    ready to vagrant up your first virtual environment! Please read

    the comments in the Vagrantfile as well as documentation on

    vagrantup.com for more information on using Vagrant.

3.8. Создаем виртуальную машину и входим в нее.

    root@pc-01:/mnt/disk-data/data/0-HW/HW-01/VM-02# vagrant up                            

    Bringing machine 'default' up with 'virtualbox' provider...

    default: Machine booted and ready!

3.9. root@pc-01:/mnt/disk-data/data/0-HW/HW-01/VM-02#

    vagrant ssh

Last login: Mon May 3 19:09:15 2021 from 10.0.2.2

[vagrant@localhost ~]$

    uname -r

    5.12.1-1.el7.elrepo.x86_64

3.10. Box (centos-7.7.1908-kernel-5-x86_64-Minimal.box) размещен на vagrant.cloud.com по адресу:

    https://app.vagrantup.com/Aleksey-Sa/boxes/centos-7-5

3.11. Установка из созданного шаблона: 
    
    vagrant init Aleksey-Sa/centos-7-5
