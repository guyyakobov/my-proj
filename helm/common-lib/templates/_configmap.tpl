{{- define "common.configmap" -}}
{{- $common := .Values.common | default (dict) }}
{{- $configMapAnnotations := mergeOverwrite (deepCopy (default (dict) $common.annotations)) (default (dict) .Values.configMapAnnotations) }}
{{- with .Values.configMap }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "common.fullname" $ }}
  labels:
    {{- include "common.labels" $ | nindent 4 }}
  {{- with $configMapAnnotations }}
  annotations:
    {{- include "common.renderStringMap" . | nindent 4 }}
  {{- end }}
data:
  {{- include "common.renderStringMap" . | nindent 2 }}
{{- end }}
{{- end }}
