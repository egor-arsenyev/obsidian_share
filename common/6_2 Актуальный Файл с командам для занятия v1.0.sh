# Подготовка
Проверка A-записей на reg.ru, на указание актуального ip.
Бекап (Snapshot) ВМ

# Создаем скрипт автоматической установки Docker и необходимых файлов конфигураций
nano install2.sh

#!/bin/bash
# Получаем IP адрес машины, на которой запускается скрипт
vm_ip=$(ip a | awk '/inet / && !/127.0.0.1/ {gsub(/\/.*/, "", $2); print $2; exit}')
echo "IP Машины: "$vm_ip

#Проверяем, является ли пользователь root'ом
if [ "$EUID" -eq 0 ]; then
    echo "Этот скрипт не должен запускаться с правами root. Запустите его от имени обычного пользователя."
    exit 1
fi

# Получаем имя текущего пользователя
current_user=$USER

# Создаем необходимые каталоги для docker-compose.yml
user_home=$(eval echo ~$current_user)
mkdir -p $user_home

# Генерируем уникальные порты для пользователя
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
#nginx_domain=dev-iot-101
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
cat > "$user_home/docker-compose.yml" << EOF
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

  nginx:
    image: nginx:mainline-alpine-slim
    network_mode: bridge
    volumes:
      - "$user_home/nginx/conf:/etc/nginx/conf.d"
      - "$user_home/nginx/html:/usr/share/nginx/html"
      - "$user_home/certbot/conf:/etc/letsencrypt"
      - "$user_home/certbot/www:/var/www/certbot"
    environment:
      - TZ=Europe/Moscow
    ports:
      - "$nginx_port1:80"
      - "$nginx_port2:443"
    command: '/bin/sh -c ''while :; do sleep 24h & wait \$\${!}; nginx -s reload; done & nginx -g "daemon off;"'''
    restart: unless-stopped

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

mkdir -m 755 -p $user_home/nginx/conf
mkdir -m 755 -p $user_home/nginx/html
mkdir -m 755 -p $user_home/certbot/conf
mkdir -m 755 -p $user_home/certbot/www
mkdir -m 755 -p $user_home/inadyn

# Создаем файлы конфигурации для inadyn для текущего пользователя
cat > "$user_home/inadyn/inadyn.conf" << EOF
# In-A-Dyn v2.0 configuration file format
period = 60
user-agent = Mozilla/5.0

provider no-ip.com {
    username    = $inadyn_username
    password    = $inadyn_password
    hostname    = $inadyn_hostname
}
EOF

# Создаем файлы конфигурации для NGINX для текущего пользователя
cat > "$user_home/nginx/conf/nginx.conf" << EOSF
server {
    listen 80;
    server_name $nginx_3rd_domain.$nginx_domain.ru;
    return 301 https://$nginx_3rd_domain.$nginx_domain.ru\$request_uri;
}

server {
    listen 80;
    server_name $nginx_3rd_domain.$nginx_domain.ru;
    root /usr/share/nginx/html/$nginx_domain.ru;
    
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}

server {
    listen 443 ssl http2;
    server_name $nginx_3rd_domain.$nginx_domain.ru;
    root /usr/share/nginx/html/$nginx_domain.ru;

    ssl_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$nginx_domain.ru/privkey.pem;

    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}


####################################################################


# Grafana primary listener and redirect
server {
  listen 80;
  server_name grafana-$nginx_3rd_domain.$nginx_domain.ru;
  return 301 https://\$host\$request_uri;
}

# Grafana ssl config
server {
  listen 443 ssl http2;
  server_name grafana-$nginx_3rd_domain.$nginx_domain.ru;
  
  ssl_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
  ssl_trusted_certificate /etc/letsencrypt/live/$nginx_domain.ru/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$nginx_domain.ru/privkey.pem;
  
  location / {
  http2_push_preload on;
  proxy_pass http://$vm_ip:$grafana_port;
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

# Создаем скрипт для настройки пользовательских параметров
cat > "$user_home/settings2.sh" << EOF
#!/bin/bash
docker exec -it $current_user-certbot-1 sh -c 'certbot -d *.$nginx_domain.ru -d $nginx_domain.ru --manual --preferred-challenges dns certonly --server https://acme-v02.api.letsencrypt.org/directory'
EOF

#Скачивается папка с сайтом-заглушкой и названием домена в папку /nginx/html/
wget https://codeload.github.com/VladislavGatsenko/gb-iot/zip/refs/heads/main -O $nginx_domain.zip
unzip $nginx_domain.zip -d $user_home/nginx/html/
mv "$user_home/nginx/html/"* "$user_home/nginx/html/$nginx_domain.ru"

# Устанавливаем владельца и разрешения для созданных файлов конфигурации
chown $current_user:$current_user "$user_home/docker-compose.yml"
chown $current_user:$current_user "$user_home/settings2.sh"
chown $current_user:$current_user "$user_home/nginx/conf/nginx.conf"
chown $current_user:$current_user "$user_home/inadyn/inadyn.conf"
chown $current_user:$current_user "$user_home/nginx/html/$nginx_domain.ru"
chmod 755 "$user_home/docker-compose.yml"
chmod 755 "$user_home/settings2.sh"
chmod 755 "$user_home/nginx/conf/nginx.conf"
chmod 755 "$user_home/inadyn/inadyn.conf"
chmod 755 "$user_home/nginx/html/$nginx_domain.ru"

echo 
echo "Перед запуском Nginx не забыть вставить сертификаты (если они есть) в папку $user_home/certbot/conf/live/$nginx_domain.ru . Если их нет, они будут сгенерированы позже командой bash settings2.sh"
______________________________________________________



bash install2.sh

docker compose down

#скопировать папку с сайтом-заглушкой и названием домена (например dev-iot.ru) в папку /nginx/html/

docker compose up -d

(далее шаг выполняет преподаватель или студент со своим личным доменом. По окончании преподаватель скидывает в чат папку с сертификатами (или ссылку на диск), которую необходимо полоджить в папку ВМ certbot/conf/live/dev-iot.ru)
(чтобы скопировать сертификаты с linux к себе на машину, можно выполнить команду sudo scp -r /home/student/certbot/conf/live/dev-iot.ru vladislavgatsenko@192.168.50.34:/Users/vladislavgatsenko/)
(для универсальности сертификаты можно грузить в общую папку на Drive )

bash settings2.sh

docker compose down

docker compose up -d

docker ps

Проброс портов (для nginx и mqtt и wg)

Проверка обновления адреса на noip.com
Проверка A записи gvi-101.dev-iot.ru с доступом к сайту-заглушке
Проверка CNAME записи grafana-gvi-101.dev-iot.ru с доступом к нужному сервису
