{{- define "common.service" -}}
{{- $common := .Values.common | default (dict) }}
{{- $service := .Values.service | default (dict) }}
{{- $headless := .Values.headlessService | default (dict) }}
{{- $serviceAnnotations := (mergeOverwrite (deepCopy (default (dict) $common.annotations)) (default (dict) $service.annotations)) }}
{{- $headlessAnnotations := (mergeOverwrite (deepCopy (default (dict) $common.annotations)) (default (dict) $headless.annotations)) }}
{{- $serviceEnabled := dig "enabled" true $service }}
{{- $headlessEnabled := dig "enabled" false $headless }}
{{- if $serviceEnabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with $serviceAnnotations }}
  annotations:
    {{- include "common.renderStringMap" . | nindent 4 }}
  {{- end }}
spec:
  {{- with $service.type }}
  type: {{ . }}
  {{- end }}
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
  ports:
    {{- with $service.ports }}
    {{- toYaml . | nindent 4 }}
    {{- else }}
    - name: {{ default "http" $service.portName | quote }}
     * port: {{ $service.port }}
     * targetPort: {{ $service.targetPort | default $service.port }}
     * {{- if and $service.nodePort (or (eq $service.type "NodePort") (eq $service.type "LoadBalancer")) }}
      nodePort: {{ $service.nodePort }}
      {{- end }}
      {{- with $service.protocol }}
      protocol: {{ . }}
      {{- end }}
    {{- end }}
{{- end }}

{{ if $headlessEnabled }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.headlessServiceName" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with $headlessAnnotations }}
  annotations:
    {{- include "common.renderStringMap" . | nindent 4 }}
  {{- end }}
spec:
  type: ClusterIP
  clusterIP: None
  {{- if hasKey $headless "publishNotReadyAddresses" }}
  publishNotReadyAddresses: {{ $headless.publishNotReadyAddresses }}
  {{- end }}
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
  ports:
    {{- if $headless.ports }}
    {{- toYaml $headless.ports | nindent 4 }}
    {{- else }}
    - name: {{ default "http" $service.portName | quote }}
      port: {{  $headless.port }}
      targetPort: {{ $headless.targetPort | default $headless.port }}
      {{- with $headless.protocol }}
      protocol: {{ . }}
      {{- end }}
    {{- end }}
{{- end }}
{{- end }}