{{- define "common.ingress" -}}
{{- $common := .Values.common | default (dict) }}
{{- $ingress := .Values.ingress | default (dict) }}
{{- $service := .Values.service | default (dict) }}
{{- $ingressAnnotations := (mergeOverwrite (deepCopy (default (dict) $common.annotations)) (default (dict) .Values.ingressAnnotations)) }}
{{- $ingressEnabled := $ingress.enabled | default false }}
{{- if $ingressEnabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with $ingressAnnotations }}
  annotations:
    {{- include "common.renderStringMap" . | nindent 4 }}
  {{- end }}
spec:
  {{- with $ingress.className }}
  ingressClassName: {{ . | quote }}
  {{- end }}
  {{- with $ingress.defaultBackend }}
  defaultBackend:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ingress.tls }}
  tls:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ingress.hosts }}
  rules:
    {{- range . }}
    - {{- with .host }}
      host: {{ . | quote }}
      {{- end }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ default "/" .path | quote }}
            pathType: {{ .pathType | default "Prefix" }}
            backend:
              {{- with .backend }}
              {{- toYaml . | nindent 14 }}
              {{- else }}
              service:
                name: {{ .serviceName | default (include "common.fullname" $) }}
                port:
                  {{- if kindIs "string" $service.port }}
                  name: {{ $service.port | quote }}
                  {{- else }}
                  number: {{ $servicePort }}
                  {{- end }}
              {{- end }}
          {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
