## Что в этом примере

job_with_secrets: получает секрет `gitlab-secret/${CI_PROJECT_PATH}/mysecret` используя роль `read-by-gitlab-project`

Так как имя проекта `project-2` то доступ есть только к `gitlab-secret/project-2/mysecret`
