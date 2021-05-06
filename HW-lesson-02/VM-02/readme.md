### Информация

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

Далее будет выполнена автоматическая настройка RAID10 и 5 разделов.








    
        
