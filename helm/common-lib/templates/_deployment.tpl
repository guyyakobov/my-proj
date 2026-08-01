{{- $common := default (dict) .Values.common -}}
{{- define "common.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with (mergeOverwrite (deepCopy (default (dict) $common.Annotations)) (default (dict) .Values.deploymentAnnotations)) }}
  annotations:
    {{- include "common.renderStringMap" . | nindent 4 }}
  {{- end }}
  spec:
    {{- if not .Values.hpa.enabled }}
    replicas: {{ .Values.replicas }}
    {{- end }}
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.labels" . | nindent 8 }}
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        {{- with (mergeOverwrite (deepCopy .Values.common.Annotations) .Values.podAnnotations) }}
        {{- include "common.renderStringMap" . | nindent 4 }}
        {{- end }}
    spec:
      {{- with .Values.imagePullSecrets  }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}


      