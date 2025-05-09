**Telegraf от InfluxData** — это **open source агент для сбора, обработки и отправки метрик и данных временных рядов**, разработанный компанией InfluxData. Вот ключевая информация о нём:
### **Основные характеристики**
1. **Назначение**  
   Telegraf собирает данные из различных источников (системы, IoT-устройства, облачные сервисы, базы данных) и отправляет их в хранилища, такие как [[InfluxDB]], Prometheus, Azure Monitor и другие .  
   Примеры источников: CPU, память, диски, Docker, Nginx, Kafka, [[MQTT]], REST API и более 150 плагинов .

2. **Архитектура**  
   - Работает на **плагинах**:
     - **Input** — сбор данных (например, `cpu`, `mem`, `disk`).
     - **Process** — фильтрация и преобразование данных.
     - **Aggregate** — агрегация метрик (например, среднее значение).
     - **Output** — отправка данных в хранилища (InfluxDB, [[Grafana]], Azure Monitor) .
   - Написан на **Go**, не требует внешних зависимостей и потребляет минимум ресурсов .

3. **Установка и настройка**  
   - Устанавливается через пакетные менеджеры (например, `apt` для Debian/Ubuntu, `yum` для CentOS) или вручную .
   - Конфигурация через **TOML-файл**, который генерируется командой `telegraf -sample-config` с фильтрацией плагинов:
     ```bash
     telegraf -sample-config -filter cpu:mem:disk -outputfilter influxdb > telegraf.conf
     ```

---
### **Примеры использования**
1. **Мониторинг серверов**  
   Собирает метрики CPU, памяти, дисков и сетевых интерфейсов, отправляя их в InfluxDB для визуализации в Grafana или Chronograf .

2. **Интеграция с облачными сервисами**  
   Например, отправка пользовательских метрик с виртуальных машин Linux в **Azure Monitor** через плагин `azure_monitor` .

3. **IoT-устройства**  
   Поддерживает сбор данных с датчиков через MQTT, ModBus, OPC-UA и другие протоколы .

---
### **Преимущества**
- **Гибкость**: Поддержка сотен плагинов и возможность написания кастомных .
- **Простота**: Единый бинарный файл, минимальная настройка .
- **Надёжность**: Буферизация данных при недоступности хранилища и автоматическое восстановление .
- **Кросс-платформенность**: Работает на Linux, Windows (через WMI или SNMP), Docker .

---
### **Ограничения**
- Для расширенной аналитики требуется связка с [[InfluxDB]] и [[Grafana]] .
- Некоторые плагины для Windows требуют ручной настройки (например, WMI-запросы) .

---
### **Стек технологий**  
Telegraf часто используют в связке с:
- **[[InfluxDB]]** — база данных для временных рядов.
- **[[Grafana]]** — инструмент визуализации.
- **Kapacitor** (опционально) — обработка данных в реальном времени.  
Этот стек называют **TICK** (Telegraf, InfluxDB, Chronograf, Kapacitor) .

---
### **Где найти документацию?**
- Официальная документация: [docs.influxdata.com/telegraf](https://docs.influxdata.com/telegraf/v1/) .
- Примеры конфигураций и обсуждения на GitHub: [github.com/influxdata/telegraf](https://github.com/influxdata/telegraf) .
