### Необходимые компоненты

1)  ПО для виртуализации и создания виртуальных машин:
	
	Необходимо создать учетную запись на портале Broadcom (через VPN) с регионом US, после чего загрузить установщик. Для загрузки необходимо указать валидный адрес для US.
	
	Win/Linux (бесплатно для некоммерческого использования)
	VMware Workstation Pro 17.0 for Personal Use:
	support.broadcom.com/group/ecx/productdownloads?subfamily=VMware+Workstation+Pro

	MacOS (бесплатно для некоммерческого использования)
	VMware Fusion 13 Pro for Personal Use:
	support.broadcom.com/group/ecx/productdownloads?subfamily=VMware+Fusion

	Или загрузка версии 17.6.3 / 13.6.3 по ссылке:
	Windows. VMware-Workstation-Full-17.6.3-24583834.exe: clck.ru/3JKmKJ
	Linux. VMware-Workstation-Full-17.6.3-24583834.x86_64.bundle: clck.ru/3JKmKL
	MacOS. VMware-Fusion-13.6.3-24585314_universal.dmg: clck.ru/3JKmKP

2) [[SSH]] клиент:

	Termius for Windows: termius.com/free-ssh-client-for-windows
	Termius for Linux: termius.com/free-ssh-client-for-linux
	Termius for MacOS: termius.com/free-ssh-client-for-mac-os

3) Linux Debian 12.10

	3.1) Последний актуальный стабильный net-install образ для платформы x86(amd64) debian-12.10.0-amd64-netinst.iso :
	cdimage.debian.org/debian-cd/current/amd64/iso-cd/
 
4) Проверить статус виртуализации в BIOS (должна быть включена)

5) Скачать файл с командами из приложения к уроку
![[4_2 Актуальный Файл с командам для занятия v1.0.sh]]


### Создание виртуальной машины

- Создаем новую виртуальную машину

- Выбираем типовую установку 

- Указываем путь к ISO образу

- Указываем желаемое имя виртуальной машины и локацию, где она будет установлена

- Определяем пространство, которое ОС может занимать на диске

- Максимальный размер, занимаемый на диске, не забирает память сразу, это просто максимум, который может занимать ОС на дисковом пространстве

- Снимаем галочку "автоматический запуск виртуальной машины после создания" и переходим в меню `Costumize Hardware` : ^fdc854
	- Задаем размер оперативной памяти, доступной виртуальной машине (достаточно 4 GB).
	- Задаем количество процессоров - 1, количество ядер - достаточно 4 (главное не указывать значение большее, чем реальное количество ядер процессора). В софте для виртуализации поток также считается отдельным ядром.
	- Настройка сетевого адаптера - режим подключения Bridged (Мост). Это необходимо, чтобы сказать виртуальной машине использовать тот сетевой адаптер, который реально установлен в ПК. Т.е. ВМ как и обычный ПК получит по DHCP адрес от роутера и будет еще одним устройством в домашней локальной сети. 
		- **ВНИМАНИЕ!** В ходе дальнейшей установки ОС возникла проблема с подключением к сети. в VMware почему-то некорректно работает автоопределение сетевого адаптера, надо в настройках вручную выбрать свой адаптер вот мануал:  https://youtu.be/C-olzOjKeCA?si=kqbokOLXTAVEpyiD)

* После создания ВМ нужно сделать **Snapshot** - снимок состояния виртуальной машины, позволяет быстро откатить состояния ВМ, если что-то пошло не так.

- Запускаем ВМ
![[Pasted image 20250330230524.png]]

### Установка Linux Debian на виртуальную машину:

**Advanced options** -> **Graphical expert install** -> 
-> **Choose language (English)** -> Select your location (Other->Europe->Ru->Us->Continue)->
-> **Access software for a blind**... - skip
-> **Configure the speech synth**.. - skip
-> **Configure the keyboard** (Amrerican English) 
-> **Detect and mount installation media** -> 
-> **Load installer components from the installation media** ->Continue(*не выбираем доп. компоненты для минимального варианта установки*)->
-> **Detect network installer** (*на этом этапе должен обнаружится сетевой адаптер(в режиме Bridged) который мы указали в настройках*)->
-> **Configure the network** -> Auto-configure networking (Yes)->
	*Если автоконфигурация сети не удалась, выбираем No и вручную задаем параметры сети:*
	**IP-adress** - задать свободный IP-адрес из диапазона адресов локальной сети (можно посмотреть на роутере)
	**Netmask** - можно использовать значение по умолчанию
	**Gateway** - если конфигурация домашней сети типовая, то моно использовать значение по умолчанию (это тот адрес по которому мы заходим в настройки роутера)
	**Name server addresses** - адрес DNS-сервера - указываем либо 1.1.1.1 либо 8.8.8.8
-> 3 -> Hostname (*указываем название машины, например dev-iot*)-> Domain name (*оставляем пустым*) ->
-> **Set up users and passwords** -> Allow login as root (No) -> Full name for the new user (egor)(*логин для входа в систему, также используется для входа по SSH*) -> Username for account (eg or) -> Choose a password for the new user (mxA373&o) ->
-> **Configure the clock** -> Set the clock using NTP (Yes) -> Contniue -> Select you time zone (Moscow) ->
-> **Detect disks** ->
-> **Partition disks** -> Partitioning method (guided -use entire disk) -> Continue -> Partitioning scheme (All files in one partition) -> Continue -> Write the changes to disks (Yes) ->
-> **Install the base system** -> Kernel to install (linux-image-amd64) -> Drivers to include in the initrd (targeted (*чтобы уменьшить размер системы*)) -> 
-> **Select and install software** -> No -> Use a network mirror (Yes) -> Protocol (http) -> Debian mirror country (Ru) -> Debian mirror (любое зеркало) -> Continue -> Yes -> No -> No -> Yes-> Continue
-> **Select and install software** ->  Updates...(No automatic updates) -> No -> Choose software to install (только  SSH server) ->
-> **Install the GRUB boot loader** -> No -> Yes -> Continue ->
-> **Finish the installation** -> Yes -> Continue

Далее система перезагрузится 

После успешной перезагрузки мы попадем в консоль Linux Debian где необходимо ввести логин и пароль для авторизации в системе

**ВНИМАНИЕ!** Не забыть сделать Snapshot. 

### Настройка Termius

Hosts -> NEW HOST -> Addres (указать адрес виртуальной машины (*можно узнать командой "ip a"*)) -> General (указать желаемое название)  -> SSH on 22 port (указываем логин и пароль для подключения (login: egor password: mxA373&o))

Конфигурация окончена далее можно выполнить подключение.



