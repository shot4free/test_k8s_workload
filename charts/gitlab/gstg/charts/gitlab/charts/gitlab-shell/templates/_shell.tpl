{{/*
Return the string 'PROXY'

The string 'PROXY' ensures the use of ProxyProtocol decoding in a TCP service.
This string is exactly compared with the string 'PROXY' when using nginx-ingress (in capital letters).
See: https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/
*/}}
{{- define "gitlab.shell.tcp.proxyProtocol" -}}
{{- $inbound := "" -}}
{{- if .Values.global.shell.tcp.proxyProtocol -}}
{{-   $inbound = "PROXY" -}}
{{- end -}}
{{- $outbound := "" -}}
{{- if .Values.config.proxyProtocol -}}
{{-   $outbound = "PROXY" -}}
{{- end -}}
:{{ $inbound }}:{{ $outbound }}
{{- end -}}
