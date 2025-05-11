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


## Namespaces

```shell
stronghold namespace create ns1
stronghold namespace create -namespace=ns1 ns2
stronghold secrets enable -namespace=ns1/ns2 -path=secret kv-v2
stronghold kv put -namespace=ns1/ns2 secret/foo key=value
stronghold kv get -namespace=ns1/ns2 secret/foo
stronghold kv get -namespace=ns1 ns2/secret/foo
stronghold kv get -namespace= ns1/ns2/secret/foo
```

```shell
stronghold namespace create -namespace= a1
stronghold namespace create -namespace= a2
stronghold namespace create -namespace= a3

stronghold namespace create -namespace=a1 b1
stronghold namespace create -namespace=a1 b2

stronghold namespace create -namespace=a1/b1 c1
stronghold namespace create -namespace=a1/b1 c2

stronghold namespace create -namespace=a1/b2 c1
stronghold namespace create -namespace=a1/b2 c2

stronghold policy write -namespace=a1 admin - <<EOF
path "*" { capabilities = ["read","list","create","update","delete","sudo"] }
EOF

stronghold auth enable -namespace=a1 userpass
stronghold write -namespace=a1 auth/userpass/users/admin password="Password-1" policies=admin



stronghold policy write admin - <<EOF
path "*" { capabilities = ["read","list","create","update","delete","sudo"] }
EOF

stronghold auth enable userpass
stronghold write auth/userpass/users/admin password="Password-1" policies=admin


stronghold secrets enable -path=secret-in-a1 -namespace=a1 kv-v2
stronghold secrets enable -path=secret-in-a2 -namespace=a2 kv-v2
stronghold secrets enable -path=secret-in-a3 -namespace=a3 kv-v2
stronghold secrets enable -path=secret-in-a1-b1 -namespace=a1/b1 kv-v2
stronghold secrets enable -path=secret-in-a1-b2 -namespace=a1/b2 kv-v2
stronghold secrets enable -path=secret-in-a1-b1-c1 -namespace=a1/b1/c1 kv-v2
```

Пользователи могут выполнять запросы к API в рамках определенного пространства имен, установив заголовок `X-Vault-Namespace` на абсолютный или относительный путь пространства имен. Относительные пути пространств имен считаются дочерними пространствами имен вызывающего пространства. Вы также можете указать абсолютный путь пространства имен без использования заголовка `X-Vault-Namespace`.

Stronghold создает полностью квалифицированный путь пространства имен, основываясь на вызывающем пространстве имен и заголовке `X-Vault-Namespace`, чтобы направить запрос в соответствующее пространство имен. Например, следующие запросы все направляются в пространство имен `ns1/ns2/secret/foo`:

1. Путь: `ns1/ns2/secret/foo`
2. Путь: `secret/foo`, Заголовок: `X-Vault-Namespace: ns1/ns2/`
3. Путь: `ns2/secret/foo`, Заголовок: `X-Vault-Namespace: ns1/`

## TODO

 [Restricted paths](https://developer.hashicorp.com/vault/docs/enterprise/namespaces#restricted-api-paths)

