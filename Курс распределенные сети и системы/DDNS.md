
**DDNS** – Dynamic DNS представляет собой технологию, которая позволяет автоматически обновлять записи DNS (Domain Name System) для динамически изменяющихся IP-адресов устройств в сети. Она позволяет использовать постоянное доменное имя для доступа к устройствам или серверам с динамическим IP-адресом (например, домашнему роутеру, камере наблюдения или серверу).

**Аналог:** DDNS работает как «автоответчик» для вашего IP-адреса. Даже если адрес меняется, система всегда сообщает: «Ищите меня здесь!».

![[Pasted image 20250329195809.png]]

#### Зачем это нужно?

Большинство домашних и мобильных интернет-провайдеров выдают **динамические IP-адреса**, которые меняются при переподключении к сети. Если ваш IP-адрес постоянно меняется:

- Невозможно получить стабильный доступ к домашнему серверу, камере или NAS.
- Придется каждый раз узнавать новый IP и вводить его вручную.

**DDNS решает эту проблему**, связывая ваше доменное имя с текущим IP-адресом, даже если он изменился.

#### Как это работает?

1. Вы регистрируетесь у **DDNS-провайдера** (например, No-IP, DuckDNS, DynDNS) и получаете домен вида `your-name.ddns.net`.

2. На устройстве (роутере, ПК, сервере) устанавливается **DDNS-клиент**, который:
    - Регулярно проверяет текущий IP-адрес.
    - Отправляет его на сервер провайдера при изменении.

3. DNS-запись вашего домена автоматически обновляется, указывая на новый IP.

#### Пример использования

Допустим, у вас есть:
- Домашняя камера с IP `87.120.45.67`.
- Вы настроили DDNS-домен `mycamera.ddns.net`.

Если провайдер изменит ваш IP на `92.154.11.22`, DDNS-клиент сразу обновит запись, и вы сможете продолжать подключаться по `mycamera.ddns.net`, не заметив изменений.

#### Где применяется?

- **Удаленный доступ** к домашней сети, NAS, камерам, умным устройствам.
- **Хостинг серверов** (веб-сайт, игровой сервер) без покупки статического IP.
- **IoT-устройства** (например, управление умным домом из любой точки мира).

#### Настройка DDNS

1. **Выберите провайдера**:
    - Бесплатные: No-IP, DuckDNS, FreeDNS.
    - Платные: DynDNS, Cloudflare (с API).
        
2. **Создайте аккаунт и домен** (например, `myhome.ddns.net`).

3. **Настройте клиент**:
    - На роутере: В разделе «DDNS» укажите логин, пароль и домен.
    - На ПК: Установите программу вроде **DDNS Updater**.

4. **[[Проброс портов|Пробросьте порты]]** на роутере для доступа к нужному устройству.

#### Плюсы DDNS

- Не нужно платить за статический IP.
    
- Автоматическое обновление адреса.
    
- Простая интеграция с домашними устройствами.
    

#### Минусы

- Зависимость от стороннего сервиса (если провайдер отключится, домен перестанет работать).
- Бесплатные аккаунты часто требуют подтверждения активности раз в 30 дней.
- Риски безопасности: открытие портов может сделать устройство уязвимым.

#### **DDNS vs Статический DNS**

|Параметр|DDNS|Статический DNS|
|---|---|---|
|**IP-адрес**|Динамический (меняется)|Постоянный|
|**Стоимость**|Часто бесплатно|Требуется статический IP (платно)|
|**Обновление**|Автоматическое|Вручную (если IP меняется)|
|**Использование**|Домашние сети, тестовые среды|Корпоративные серверы, сайты|
#### **Советы**

- Используйте **Cloudflare** как DDNS-провайдера, если у вас собственный домен — это надежнее и безопаснее.
- Настройте **автоматическое обновление** на роутере, чтобы не зависеть от ПК.
- Для безопасности ограничьте доступ по IP или используйте **VPN** вместо открытия портов.

