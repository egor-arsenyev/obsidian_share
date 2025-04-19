![[6_2 Актуальный Файл с командам для занятия v1.0.sh]]

```bash
# Подготовка
# * Проверка A-записей на reg.ru, на указание актуального ip.
# * Бекап (Snapshot) ВМ

# Создаем скрипт автоматической установки Docker и необходимых файлов конфигураций
nano install2.sh
```

Начало файла `install2.sh`
``` bash
#!/bin/bash

# Получаем IP адрес машины, на которой запускается скрипт

#В этой строке выполняется следующая последовательность действий:
#1. Команда `ip a` выводит информацию о всех сетевых интерфейсах системы.
#2. Вывод команды `ip a` передаётся через конвейер (`|`) в утилиту `awk`, которая используется для обработки текста.
#3. В `awk` задано условие `/inet / && !/127.0.0.1/`, которое ищет строки, содержащие `inet` (что указывает на IP-адрес), но исключает адрес `127.0.0.1` (локальный адрес loopback).
#4. Для найденной строки выполняется действие `gsub(/\/.*/, "", $2)`, которое удаляет всё после символа `/` в поле `$2` (IP-адрес).
#5. Затем команда `print $2` выводит очищенный IP-адрес.
#6. Команда `exit` завершает работу `awk` после вывода первого найденного IP-адреса.
#7. Результат всей команды присваивается переменной `vm_ip` с помощью конструкции `vm_ip=$(...)`.
#Таким образом, эта строка получает IP-адрес машины, на которой запускается скрипт, исключая локальный адрес `127.0.0.1`.
vm_ip=$(ip a | awk '/inet / && !/127.0.0.1/ {gsub(/\/.*/, "", $2); print $2; exit}')

echo "IP Машины: "$vm_ip

#Проверяем, является ли пользователь root'ом
if [ "$EUID" -eq 0 ]; then
    echo "Этот скрипт не должен запускаться с правами root. Запустите его от имени обычного пользователя."
    exit 1
fi

# Получаем имя текущего пользователя
# Знак `$` в скриптах используется для обращения к значениям переменных
current_user=$USER

# Создаем необходимые каталоги для docker-compose.yml

# YML-файлы очень привередливы к пробелам и отступам

#Строка `user_home=$(eval echo ~$current_user)` выполняет следующее:
#1. Переменная `$current_user` содержит имя текущего пользователя.
#2. Команда `echo ~$current_user` выводит домашний каталог текущего пользователя (например, `/home/username`).
#3. Команда `eval` используется для выполнения результата команды `echo`, что позволяет получить путь к домашнему каталогу пользователя в виде строки.
#4. Результат присваивается переменной `user_home`.
#Строка `mkdir -p $user_home` выполняет следующее:
#1. Команда `mkdir -p` создаёт каталог, указанный в аргументе, если он ещё не существует.
#2. Флаг `-p` гарантирует, что команда не будет выдавать ошибку, если каталог уже существует, и позволяет создавать вложенные каталоги.
user_home=$(eval echo ~$current_user)
mkdir -p $user_home

# Создаем переменные с уникальными портами для пользователя, чтобы далее вместо цифр оперировать осмысленными названиями. Номера портов - дефолтные для каждого из сервисов. Но в принципе можно использовать любой номер в диапазоне от 1024 до 65535
mosquitto_port=1883
influxdb_port=8086
grafana_port=3000
nodered_port=1880
wireguard_port=51820
telegraf_port1=8092
telegraf_port2=8094
telegraf_port3=8125
nginx_port1=80
nginx_port2=443

# Задаем доменное имя для конфигурации nginx без www. и без .ru
#nginx_domain=dev-iot

# Назначание флагов:
#**`read -p`** — флаг `-p` используется с командой `read` для вывода подсказки перед ожиданием ввода данных от пользователя.
#**`echo -n`** — флаг `-n` используется с командой `echo` для вывода текста без перевода строки в конце.
#**`read -s`** — флаг `-s` используется с командой `read` для скрытия ввода данных (например, при вводе пароля).
read -p "Введите доменное имя для конфигурации nginx без www. и без .ru: " nginx_domain
read -p "Введите среднюю часть доменного имени для ваших сервисов из инициалов и номера группы, например, gvi-4538 (для grafana-gvi-4538.dev-iot.ru и др.): " nginx_3rd_domain

# Задаем данные для подключения сервиса DDNS No-IP
echo -n "Введите username с сервиса NO-IP.com : "
read inadyn_username
echo -n "Введите password с сервиса NO-IP.com : "
read -s inadyn_password
echo
echo -n "Введите hostname с сервиса NO-IP.com : "
read inadyn_hostname

# Создаем docker-compose.yml для текущего пользователя

# Файл `docker-compose.yml` необходим для определения и управления мультиконтейнерными приложениями Docker. Он позволяет описать сервисы, их зависимости, настройки сети, тома и другие параметры в одном файле. Это упрощает процесс развёртывания и управления несколькими контейнерами как единым целым.
# С помощью `docker-compose.yml` можно легко запустить все необходимые контейнеры с правильно настроенными связями между ними, что особенно полезно при разработке и тестировании приложений, состоящих из нескольких сервисов.

# Вместо переменных будут подставлены необходимые нам значения 
cat > "$user_home/docker-compose.yml" << EOF
```

Пересоздаем файл `docker-compose.yml`
Настройки для Mosquitto, Telegraph, InfluxDB, Nodered, Wireguard описаны в [[Алгоритм развертывания сервисов в Docker контейнерах#^975290| алгоритме развертывания сервисов в Docker контейнерах]]. Для этих сервисов настройки остаются прежними. Добавляются настройки для [[NGINX]], [[Certbot]] и [[Inadyn]]
```yaml
services:
  mosquitto:
    image: eclipse-mosquitto
    network_mode: bridge
    user: $(id -u $current_user):$(id -g $current_user)
    ports:
      - "$mosquitto_port:1883"
    volumes:
      - "$user_home/mosquitto/config:/mosquitto/config"
      - "$user_home/mosquitto/data:/mosquitto/data"
      - "$user_home/mosquitto/log:/mosquitto/log"
    environment:
      - TZ=Europe/Moscow
    restart: unless-stopped

  telegraf:
    image: telegraf:alpine
    network_mode: bridge
    user: $(id -u $current_user):$(id -g $current_user)
    volumes:
      - "$user_home/telegraf/conf:/etc/telegraf/telegraf.d"
    ports:
      - "$telegraf_port1:8092/tcp"
      - "$telegraf_port1:8092/udp"
      - "$telegraf_port2:8094/tcp"
      - "$telegraf_port2:8094/udp"
      - "$telegraf_port3:8125/tcp"
      - "$telegraf_port3:8125/udp"
    environment:
      - TZ=Europe/Moscow
    depends_on:
      - mosquitto
      - influxdb
    restart: unless-stopped
  
  influxdb:
    image: influxdb:alpine
    network_mode: bridge
    user: $(id -u $current_user):$(id -g $current_user)
    ports:
      - "$influxdb_port:8086"
    volumes:
      - "$user_home/influxdb/data:/var/lib/influxdb2"
      - "$user_home/influxdb/conf:/etc/influxdb"
      - "$user_home/influxdb/engine:/var/lib/influxdb2/engine"
    environment:
      - TZ=Europe/Moscow
    restart: unless-stopped

  grafana:
    image: grafana/grafana
    network_mode: bridge
    user: $(id -u $current_user):$(id -g $current_user)
    volumes:
      - "$user_home/grafana/data:/var/lib/grafana"
      - "$user_home/grafana/conf:/etc/grafana"
      - "$user_home/grafana/log:/var/log/grafana"
    ports:
      - "$grafana_port:3000"
    environment:
      - PUID=$(id -u $current_user)
      - PGID=$(id -g $current_user)
      - TZ=Europe/Moscow
    restart: unless-stopped

  nodered:
    image: nodered/node-red:latest-minimal
    network_mode: bridge
    user: $(id -u $current_user):$(id -g $current_user)
    volumes:
      - "$user_home/node-red/data:/data"
    ports:
      - "$nodered_port:1880"
    environment:
      - TZ=Europe/Moscow
    restart: unless-stopped

  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    network_mode: bridge
    privileged: true
    volumes:
      - "$user_home/wireguard/config:/config"
    ports:
      - "$wireguard_port:51820/tcp"
      - "$wireguard_port:51820/udp"
    environment:
      - PUID=$(id -u $current_user)
      - PGID=$(id -g $current_user)
      - TZ=Europe/Moscow
      - SERVERURL=$vm_ip #optional
      - SERVERPORT=$wireguard_port #optional
      - PEERS=10 #optional
      - PEERDNS=1.1.1.1 #optional
      - INTERNAL_SUBNET=10.13.13.0 #optional
      - ALLOWEDIPS=0.0.0.0/0 #optional
      - LOG_CONFS=false #optional
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
#---------------------------------------------------------------------------------#
  nginx:
    image: nginx:mainline-alpine-slim
    network_mode: bridge
    
#**volumes** — определяются тома для монтирования директорий хост-системы в контейнер:
# - "$user_home/nginx/conf:/etc/nginx/conf.d" — конфигурация NGINX будет храниться в директории `/etc/nginx/conf.d` внутри контейнера.
# - "$user_home/nginx/html:/usr/share/nginx/html" — файлы веб-сервера будут храниться в директории `/usr/share/nginx/html` внутри контейнера.
# - "$user_home/certbot/conf:/etc/letsencrypt" — сертификаты Let's Encrypt будут храниться в директории `/etc/letsencrypt` внутри контейнера.
# - "$user_home/certbot/www:/var/www/certbot" — файлы для работы с Certbot будут храниться в директории `/var/www/certbot` внутри контейнера.
    volumes:
      - "$user_home/nginx/conf:/etc/nginx/conf.d"
      - "$user_home/nginx/html:/usr/share/nginx/html"
      - "$user_home/certbot/conf:/etc/letsencrypt"
      - "$user_home/certbot/www:/var/www/certbot"
    environment:
      - TZ=Europe/Moscow

#**ports** — указываются порты для перенаправления трафика:
# - "$nginx_port1:80" — порт 80 контейнера будет доступен на хост-системе под номером `$nginx_port1`.
# - "$nginx_port2:443" — порт 443 контейнера будет доступен на хост-системе под номером `$nginx_port2`.
    ports:
      - "$nginx_port1:80"
      - "$nginx_port2:443"

#**command** — задаётся команда для запуска NGINX в режиме, когда он не переходит в фоновый режим (`daemon off;`), и периодически перезагружает конфигурацию
#`/bin/sh -c` — запуск оболочки Bash с параметром `-c`, который позволяет передать команду в виде строки.
#`while :; do` — начало бесконечного цикла. Символ `:` является сокращением для команды `true`, которая всегда возвращает true, заставляя цикл продолжаться бесконечно.
#`sleep 24h` — команда заставляет оболочку «спать» в течение 24 часов. Это делается для того, чтобы не перегружать систему частыми перезагрузками конфигурации.
#`wait $${!}` — после `sleep` запускается команда `wait`, которая ожидает завершения фонового процесса (в данном случае процесса `sleep`). `$${!}` — это идентификатор последнего запущенного фонового процесса.
#`nginx -s reload` — после ожидания перезапускается конфигурация NGINX с помощью сигнала `reload`. Это позволяет NGINX перечитать конфигурацию без прерывания работы.
#`done &` — завершение цикла `while` и запуск цикла в фоновом режиме, что позволяет продолжить выполнение следующих команд.
#`nginx -g "daemon off;"` — запуск NGINX с параметром `daemon off;`, который заставляет его работать в переднем плане, а не переходить в фоновый режим. Это необходимо для того, чтобы контейнер не завершился после запуска NGINX.
    command: '/bin/sh -c ''while :; do sleep 24h & wait \$\${!}; nginx -s reload; done & nginx -g "daemon off;"'''
    
# контейнер будет автоматически перезапускаться при сбоях, кроме случаев, когда он был остановлен вручную.
    restart: unless-stopped

# 1. `image: certbot/certbot:latest` — используется официальный образ `certbot`.
# 2. `volumes` — монтируются тома для хранения сертификатов и файлов, необходимых для работы `certbot`:
#    - `$user_home/certbot/conf:/etc/letsencrypt` — сертификаты и ключи Let's Encrypt.
#   - `$user_home/certbot/www:/var/www/certbot` — файлы, используемые `certbot` для проверки домена.
# 3. `environment: TZ=Europe/Moscow` — устанавливается переменная окружения `TZ` для корректного отображения времени.
# 4. `depends_on: nginx` — контейнер `certbot` зависит от контейнера `nginx`, что гарантирует, что `nginx` будет запущен до начала работы `certbot`.
# 5. `entrypoint` — задаётся точка входа для контейнера, которая обеспечивает автоматический запуск и обновление сертификатов: 
#    - `/bin/sh -c` — запуск оболочки Bash с передачей команды в виде строки.
#    - `trap exit TERM` — обработка сигнала `TERM`, чтобы корректно завершить работу контейнера.
#    - `while :; do` — начало бесконечного цикла.
#    - `certbot renew` — команда для обновления сертификатов.
#    - `sleep 24h` — ожидание в течение 24 часов перед следующим обновлением.
#    - `wait $${!}` — ожидание завершения фонового процесса `sleep`.
#    - `done;` — завершение цикла.
# 6. `restart: unless-stopped` — контейнер будет автоматически перезапускаться при сбоях, кроме случаев, когда он был остановлен вручную.
  certbot:
    image: certbot/certbot:latest
    network_mode: bridge
    volumes:
      - "$user_home/certbot/conf:/etc/letsencrypt"
      - "$user_home/certbot/www:/var/www/certbot"
    environment:
      - TZ=Europe/Moscow
    depends_on:
      - nginx
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 24h & wait \$\${!}; done;'"
    restart: unless-stopped

  inadyn:
    image: troglobit/inadyn:latest
    restart: unless-stopped
    network_mode: bridge
    volumes:
      - "$user_home/inadyn/inadyn.conf:/etc/inadyn.conf"
    environment:
      - TZ=Europe/Moscow
EOF
```

Продолжение файла `install2.sh`
```bash
# Создаем необходимые каталоги с разрешениями только для текущего пользователя, на которые мы ссылались в `docker-compose.yml`
mkdir -m 755 -p $user_home/nginx/conf
mkdir -m 755 -p $user_home/nginx/html
mkdir -m 755 -p $user_home/certbot/conf
mkdir -m 755 -p $user_home/certbot/www
mkdir -m 755 -p $user_home/inadyn

# Создаем файлы конфигурации для inadyn для текущего пользователя

cat > "$user_home/inadyn/inadyn.conf" << EOF
```

Содержимое `inadyn.conf`
```ini
# In-A-Dyn v2.0 configuration file format
#`period = 60` — интервал обновления DNS-записи в секундах. В данном случае обновление будет происходить каждые 60 секунд.
period = 60

#`user-agent = Mozilla/5.0` — строка пользовательского агента, которая будет передаваться сервером при общении с сервисом DDNS.
user-agent = Mozilla/5.0  

#`provider no-ip.com` — блок конфигурации для провайдера No-IP, содержащий учётные данные для аутентификации:
#- `username = $inadyn_username` — имя пользователя для авторизации на сервисе No-IP.
#- `password = $inadyn_password` — пароль для авторизации на сервисе No-IP.
#- `hostname = $inadyn_hostname` — hostname, который будет обновляться на сервисе No-IP.
provider no-ip.com {
    username    = $inadyn_username
    password    = $inadyn_password
    hostname    = $inadyn_hostname
}
EOF
```

Продолжение файла `install2.sh`
```bash 
  # Создаем файлы конфигурации для NGINX для текущего пользователя
cat > "$user_home/nginx/conf/nginx.conf" << EOSF
```

Содержимое `nginx.conf`
Первые три блока отвечают за работу с [[DNS-записи#^2572aa|А]] записью
Далее идет блок работы с [[Grafana]], [[InfluxDB]], [[Node-RED]]
```ini
# Когда придет запрос по 80 порту (кто-то захочет по HTTP открыть доменное имя $nginx_3rd_domain.$nginx_domain.ru) будет происходить редирект на https (3-й блок)
server {
# сервер будет слушать входящие HTTP-запросы на порту 80
    listen 80;
# имя сервера, которое будет использоваться для обработки запросов.
    server_name $nginx_3rd_domain.$nginx_domain.ru;
# все входящие HTTP-запросы будут перенаправляться на HTTPS-версию сайта с кодом ответа 301 (перенаправление навсегда)
    return 301 https://$nginx_3rd_domain.$nginx_domain.ru\$request_uri;
}

# Чтобы использовался этот блок настроек, блок выше нужно закомментировать. Тогда чтобы получить доступ к какому-либо сайту по HTTP, нужно явно указать это при вводе адреса. Если ничего не указать или указать явно HTTPS, то соответственно доступ будет предоставлен по HTTPS (блок 3)
server {
    listen 80;
    server_name $nginx_3rd_domain.$nginx_domain.ru;
    
# корневой каталог, из которого будут обслуживаться файлы
    root /usr/share/nginx/html/$nginx_domain.ru;
    
# индексный файл, который будет открываться по умолчанию
    index index.html; 
    
# - блок, описывающий обработку запросов для корневого пути.
# - `try_files \$uri \$uri/ /index.html;` — попытка найти файл по указанному пути, если файл не найден — перенаправление на индексную страницу.
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}

server {
# сервер будет слушать входящие HTTPS-запросы на порту 443 с поддержкой протокола HTTP/2.
    listen 443 ssl http2;
    server_name $nginx_3rd_domain.$nginx_domain.ru;
    root /usr/share/nginx/html/$nginx_domain.ru;  
# пути к сертификатам и ключам для HTTPS
    ssl_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$nginx_domain.ru/privkey.pem;
# index.html - в данном случае сайт заглушка
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}

####################################################################
# NGINX получает по порту 80 запрос grafana-$nginx_3rd_domain.$nginx_domain.ru и перенаправляет его по HTTPS и по тому же самому адресу
# Grafana primary listener and redirect
server {
  listen 80;
  server_name grafana-$nginx_3rd_domain.$nginx_domain.ru;
  return 301 https://\$host\$request_uri;
}

# Grafana ssl config
server {
# сервер будет слушать входящие HTTPS-запросы на порту 443 с поддержкой протокола HTTP/2.
  listen 443 ssl http2;
# имя сервера
  server_name grafana-$nginx_3rd_domain.$nginx_domain.ru;
# пути к сертификатам и ключам для HTTPS  
  ssl_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$nginx_domain.ru/privkey.pem;
# location - блок настроек обратного proxy. NGINX получает запрос и уже от своего имени внутри ситемы отправляет запрос к локальному сервису. В конфигурации NGINX описывает правила обработки запросов для определённого пути на сервере. В данном случае он применяется к корневому пути (`/`), что означает, что правила будут применяться ко всем запросам, поступающим на сервер.  
  location / {
 # включение предварительной загрузки ресурсов по протоколу HTTP/2, что может ускорить загрузку страниц
  http2_push_preload on;
# перенаправление запросов на внутренний сервер Grafana, который работает на указанном IP-адресе и порту
  proxy_pass http://$vm_ip:$grafana_port;
# настройка заголовка `Host` для корректной передачи информации о хосте на внутренний сервер  

# Настройка заголовков для корректной передачи от NGINX к Grafana, от Grafana к NGINX и от NGINX к нам. Обычно набор необходимых заголовков указывается в документации к сервису
  proxy_set_header Host \$host;
# настройка заголовков для поддержки протоколов, требующих обновления соединения (например, WebSocket)
  proxy_set_header Connection "upgrade";
  proxy_set_header Upgrade \$http_upgrade;
# передача реального IP-адреса клиента на внутренний сервер
  proxy_set_header X-Real-IP \$remote_addr;
# добавление информации о промежуточных прокси-серверах в заголовок `X-Forwarded-For`    
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
# добавление информации о версии протокола HTTP в ответ сервера
  add_header X-Http-Version \$server_protocol;

#Несколько настроек буферинка, для ускорения подключения
# включение буферизации ответов от внутреннего сервера
  proxy_buffering on;
# настройка размера буфера для ответов от внутреннего сервера
  proxy_buffer_size 8k;
  proxy_buffers 2048 8k;
  }
}

####################################################################

# Аналогично Grafana
# Influxdb primary listener and redirect

server {
  listen 80;
  server_name influxdb-$nginx_3rd_domain.$nginx_domain.ru;
  return 301 https://\$host\$request_uri;
}

# Influxdb ssl config
server {
  listen 443 ssl http2;
  server_name influxdb-$nginx_3rd_domain.$nginx_domain.ru;

  ssl_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$nginx_domain.ru/privkey.pem;

  location / {
  http2_push_preload on;
  proxy_pass http://$vm_ip:$influxdb_port;
  proxy_set_header Host \$host;
  proxy_set_header Connection "upgrade";
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  add_header X-Http-Version \$server_protocol;

  proxy_buffering on;
  proxy_buffer_size 8k;
  proxy_buffers 2048 8k;
  }
}

####################################################################

# Аналогично InfluxDB
# Nodered primary listener and redirect
server {
  listen 80;
  server_name nodered-$nginx_3rd_domain.$nginx_domain.ru;
  return 301 https://\$host\$request_uri;
}

# Nodered ssl config
server {
  listen 443 ssl http2;
  server_name nodered-$nginx_3rd_domain.$nginx_domain.ru;

  ssl_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$nginx_domain.ru/privkey.pem;

  location / {
  http2_push_preload on;
  proxy_pass http://$vm_ip:$nodered_port;
  proxy_set_header Host \$host;
  proxy_set_header Connection "upgrade";
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  add_header X-Http-Version \$server_protocol;

  proxy_buffering on;
  proxy_buffer_size 8k;
  proxy_buffers 2048 8k;
  }
}

EOSF
```

Продолжение файла `install2.sh` 
```bash
# Создаем скрипт для настройки пользовательских параметров
cat > "$user_home/settings2.sh" << EOF
```

Содержимое `settings2.sh`
``` bash
#!/bin/bash
# Запускает контейнер Docker с Certbot для получения SSL-сертификатов от Let's Encrypt. Эта команда позволяет получить SSL-сертификаты для указанного домена и использовать их для обеспечения защищённого соединения на веб-сайте.

# - `docker exec -it $current_user-certbot-1` — запуск интерактивной оболочки в контейнере с именем `$current_user-certbot-1`.
# - `sh -c` — выполнение команды в оболочке.
# - `certbot -d *.$nginx_domain.ru -d $nginx_domain.ru` — запуск Certbot для получения сертификатов для домена `$nginx_domain.ru` и всех его поддоменов (`*.$nginx_domain.ru`).
# - `--manual` — использование ручного режима для подтверждения владения доменом.
# - `--preferred-challenges dns` — выбор DNS-вызова в качестве предпочтительного способа подтверждения.
# - `certonly` — получение только сертификатов, без настройки веб-сервера.
# - `--server https://acme-v02.api.letsencrypt.org/directory` — указание сервера Let's Encrypt для получения сертификатов.
docker exec -it $current_user-certbot-1 sh -c 'certbot -d *.$nginx_domain.ru -d $nginx_domain.ru --manual --preferred-challenges dns certonly --server https://acme-v02.api.letsencrypt.org/directory'

EOF
```

Окнончание файла `install2.sh` 
```bash
#Скачивается папка с сайтом-заглушкой и названием домена в папку /nginx/html/
wget https://codeload.github.com/VladislavGatsenko/gb-iot/zip/refs/heads/main -O $nginx_domain.zip
# Распаковывается
unzip $nginx_domain.zip -d $user_home/nginx/html/
# Перемещается в нужную директорию пользователя, где в NGINX нужно хранить html-сайт
mv "$user_home/nginx/html/"* "$user_home/nginx/html/$nginx_domain.ru"

# Устанавливаем владельца и разрешения для созданных файлов конфигурации и задаем права, чтобы не было проблем с доступом у самого Docker'а
# `chown $current_user:$current_user "$user_home/docker-compose.yml"` и аналогичные команды для других файлов — меняют владельца и группу файлов на `$current_user`. Это означает, что файлы передаются в собственность текущего пользователя, что позволяет ему иметь необходимые права на доступ и изменение этих файлов.
chown $current_user:$current_user "$user_home/docker-compose.yml"
chown $current_user:$current_user "$user_home/settings2.sh"
chown $current_user:$current_user "$user_home/nginx/conf/nginx.conf"
chown $current_user:$current_user "$user_home/inadyn/inadyn.conf"
chown $current_user:$current_user "$user_home/nginx/html/$nginx_domain.ru"

# 1. `chmod 755 "$user_home/docker-compose.yml"` и аналогичные команды для других файлов — устанавливают права доступа к файлам. Значение `755` означает:
# владелец файла имеет права на чтение (`r`), запись (`w`) и выполнение (`x`);
# группа владельца и другие пользователи имеют права только на чтение и выполнение файла.
chmod 755 "$user_home/docker-compose.yml"
chmod 755 "$user_home/settings2.sh"
chmod 755 "$user_home/nginx/conf/nginx.conf"
chmod 755 "$user_home/inadyn/inadyn.conf"
chmod 755 "$user_home/nginx/html/$nginx_domain.ru"

echo
# /home/egor/certbot/conf/live/.ru
echo "Перед запуском Nginx не забыть вставить сертификаты (если они есть) в папку $user_home/certbot/conf/live/$nginx_domain.ru . Если их нет, они будут сгенерированы позже командой bash settings2.sh"

______________________________________________________
```

```bash
Выполняем команду  
bash install2.sh
```

```bash 
# Останавливаем все кнонтейнеры, т.к. у нас имеется старая конфигурация
docker compose down
```

```bsah
#скопировать папку с сайтом-заглушкой и названием домена (например dev-iot.ru) в папку /nginx/html/
```

```bash 
# Поднмаем контейнеры. Должны загрузиться образы новых сервистов
docker compose up -d

# Все контейнеры должны запуститься, кроме NGINX, т.к. мы еще не добавили SSL-сертификаты
```

``` bash
#(далее шаг выполняет преподаватель или студент со своим личным доменом. По окончании преподаватель скидывает в чат папку с сертификатами (или ссылку на диск), которую необходимо полоджить в папку ВМ certbot/conf/live/dev-iot.ru)

#(чтобы скопировать сертификаты с linux к себе на машину, можно выполнить команду sudo scp -r /home/student/certbot/conf/live/dev-iot.ru vladislavgatsenko@192.168.50.34:/Users/vladislavgatsenko/)

#(для универсальности сертификаты можно грузить в общую папку на Drive )

bash settings2.sh
```
если делаем для своего домена то запускаем `settings2.sh` и получаем дальнейшие инструкции, в частности просьбу добавить 2 [[DNS-записи#^4980ef|TXT]] записи:
1. 
	* Subdomain - _acme-challenge
	* Text - сгенерированное значение
2. 
	* Subdomain - _acme-challenge
	* Text - новое сгенерированное значение

![[Pasted image 20250413212206.png]]
![[Pasted image 20250413212622.png]]

Это нужно, чтобы данный сервис мог проверить, что действительно ли я владелец домена  и на основании этого можно выдать набор сертификатов бесплатно, на 3 месяца.

Прежде чем переходить к следующему шагу, необходимо подождать пока записи обновятся на DNS серверах. Обновились ли записи можно проверить на сервисе DIG.

Если мы делаем на групповом домене, то:
* Вручную на ВМ создаем каталог `/home/egor/certbot/conf/live/dev-iot.ru/` 
* Скачиваем с гугл-диска сертификаты, которые сгенерировал преподаватель и размещаем их по созданному пути (можно через [[SFTP]]) 

```bash
docker compose down
```

```bash
docker compose up -d
```

```bash
docker ps
```
При успешном исходе все контейнеры должны быть запущены

Проброс портов (для nginx и mqtt и wg)

Проверка обновления адреса на noip.com

Проверка A записи gvi-101.dev-iot.ru с доступом к сайту-заглушке

Проверка CNAME записи grafana-gvi-101.dev-iot.ru с доступом к нужному сервису
