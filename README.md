# Материалы к demo Deckhouse Stronghold

* cluster - пример сетапа кластера DKP + Stronghold
* gilab-ci - примеры работы со Stronghold из gitlab-ci с использованием JWT джобы
* terraform - преднастройка Stronghold для примеров
  * 01-secrets - создание секретов
  * 02-ssh - подпись ключей SSH
  * 03-database - секрет для примера с БД (postgres.yaml)
  * 04-database-access - настройки для выдачи динамический паролей к БД
  * 05-gitlab - для примеров gilab-ci
  * 06-gitlab-deploy - механизм секретов для создания токенов Kubernetes (примеры CI)
  * 07-werf-secret-key - пример хранения WERF_SECRET_KEY
