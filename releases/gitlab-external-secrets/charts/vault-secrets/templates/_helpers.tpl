{{/*
Default Vault server
*/}}
{{- define "vault-secrets.secretStoreServer" -}}
https://vault.ops.gke.gitlab.net
{{- end }}

{{/*
Default Vault auth mount path
*/}}
{{- define "vault-secrets.secretStoreMountPath" -}}
kubernetes/{{ .Values.clusterName }}
{{- end }}

{{/*
Default Vault KV version
*/}}
{{- define "vault-secrets.secretStoreVersion" -}}
v2
{{- end }}

{{/*
Default Vault KV path
*/}}
{{- define "vault-secrets.secretStorePath" -}}
k8s
{{- end }}

{{/*
Create the name of the secret store
*/}}
{{- define "vault-secrets.secretStoreName" -}}
{{ include "common.names.fullname" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vault-secrets.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end }}
