## Расширяем примеры из project-1 и project-3

Деплой в Kubernetes помощью werf, используя динамический WERF_KUBE_TOKEN - токен доступа к API K8s, который выписывает Stronghold

### Другие переменные

Можно хранить секретные значения с привязкой к env и имени проекта, секреты будут извлекаться в момент деплоя.
Секретные значения извлекаются из Stronghold по шаблонному пути 
`gitlab-secret/data/${CI_ENVIRONMENT_SLUG}/${CI_PROJECT_PATH}/mysecret` и помещаются в Secret Kubernetes
через `WERF_SET_*`. Секрет подключается к `Deployment` через `envFrom`.

