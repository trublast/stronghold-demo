## Расширяем пример из project-3

Деплой в Kubernetes помощью werf, используя динамический WERF_KUBE_TOKEN - токен доступа к API K8s, который выписывает Stronghold

### Доступ к WERF_SECRET_KEY

Дополнительно получаем WERF_SECRET_KEY для конкретного проекта, предполагается что ключи расшифровки `secret-values.yaml`
хранятся в Stronhold по пути `werf-secret/${CI_PROJECT_PATH}/werf`
