{{- define "stronghold.initcontainer" -}}
- name: secret-importer
  image: alpine
  {{- $addr := index . 0 -}}
  {{- $role := index . 1 -}}
  {{- $secrets := index . 2 }}
  env:
    - name: STRONGHOLD_ADDR
      value: {{ $addr }}
    - name: ROLE
      value: {{ $role }}
  command:
  - sh
  - -c
  - |
    apk add curl jq
    set -e
    JWT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    TOKENRESP=$(curl -s -X PUT --fail -d '{"jwt":"'$JWT'","role":"'$ROLE'"}' $STRONGHOLD_ADDR/v1/auth/kubernetes_local/login)
    STRONGHOLD_TOKEN=$(echo $TOKENRESP | jq -r .auth.client_token)
    {{- range $file, $path := $secrets }}
    RESP=$(curl -s --fail -H "X-Vault-Token: $STRONGHOLD_TOKEN" $STRONGHOLD_ADDR/v1/{{ $path }})
    echo $RESP | jq -r .data.data.{{ $file }} > /secrets/{{ $file }}
    {{- end }}
  {{- include "stronghold.volumemount" . | nindent 2 }}
{{- end -}}

{{- define "stronghold.volumemount" -}}
volumeMounts:
- mountPath: /secrets
  name: secrets-volume
{{- end -}}
