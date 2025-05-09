**TCP/IP** — это набор сетевых протоколов, которые лежат в основе работы интернета и большинства локальных сетей. Название происходит от двух ключевых протоколов: **TCP (Transmission Control Protocol)** и **IP (Internet Protocol)**. Они обеспечивают передачу данных между устройствами в сети, даже если эти устройства используют разное оборудование или операционные системы.

### Основные компоненты:

1. **TCP (Transmission Control Protocol)**  
    — Отвечает за **надёжную передачу данных**.  
    — Устанавливает соединение между отправителем и получателем («рукопожатие»).  
    — Контролирует целостность данных, порядок пакетов и повторно отправляет потерянные фрагменты.  
    — Используется, например, в веб-браузерах (HTTP/HTTPS), электронной почте (SMTP), передаче файлов (FTP).
    
2. **IP (Internet Protocol)**  
    — Отвечает за **адресацию и маршрутизацию пакетов**.  
    — Присваивает каждому устройству уникальный IP-адрес (например, `192.168.1.1` или `2001:db8::1`).  
    — Разбивает данные на пакеты и направляет их по оптимальному пути через сеть.
    

### Уровни модели TCP/IP:

Модель TCP/IP состоит из четырёх уровней (в отличие от 7-уровневой модели OSI):

1. **Прикладной уровень** (HTTP, FTP, SMTP) — взаимодействие с пользователем и приложениями.
    
2. **Транспортный уровень** (TCP, UDP) — управление передачей данных.
    
3. **Сетевой (интернет) уровень** (IP, ICMP) — маршрутизация и адресация.
    
4. **Канальный уровень** (Ethernet, Wi-Fi) — передача данных через физические среды.
    

### Пример работы:

Когда вы открываете сайт в браузере:

1. Ваш компьютер (с IP-адресом) отправляет запрос через TCP, разбивая данные на пакеты.
    
2. IP направляет эти пакеты через маршрутизаторы к серверу сайта.
    
3. Сервер принимает пакеты, TCP проверяет их целостность и собирает в исходные данные.
    
4. Вы видите страницу сайта.
    

### Почему это важно?

Без TCP/IP невозможна работа интернета, электронной почты, стриминга и других сетевых сервисов. TCP гарантирует точность данных, а IP обеспечивает их доставку «по адресу». Вместе они создают универсальный стандарт для глобальной коммуникации.