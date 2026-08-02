{{- define "common.deployment" -}}
{{- $common := .Values.common | default (dict) }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- $deploymentAnnotations := (mergeOverwrite (deepCopy (default (dict) $common.Annotations)) (default (dict) .Values.deploymentAnnotations)) }}
  {{- with  $deploymentAnnotations }}
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
      {{- $podAnnotations := (mergeOverwrite (deepCopy (default (dict) $common.Annotations)) (default (dict) .Values.podAnnotations)) }}
      {{- $configMapRollout := and .Values.configMap .Values.configMapRollout }}
      {{- if or $podAnnotations $configMapRollout }}
      annotations:
        {{- if $configMapRollout }}
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        {{- end }}
        {{- with $podAnnotations }}
        {{- include "common.renderStringMap" . | nindent 8 }}
        {{- end }}
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
      {{- if hasKey .Values "terminationGracePeriodSeconds" }}
      terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
      {{- end }}
      {{- with .Values.priorityClassName }}
      priorityClassName: {{ . | quote }}
      {{- end }}
      {{- with .Values.schedulerName }}
      schedulerName: {{ . | quote }}
      {{- end }}
      {{- with .Values.serviceAccountName }}
      serviceAccountName: {{ . | quote }}
      {{- end }}
      {{- if hasKey .Values "automountServiceAccountToken" }}
      automountServiceAccountToken: {{ .Values.automountServiceAccountToken }}
      {{- end }}
      {{- with .Values.initContainers }}
      initContainers:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Values.containerName | default ( include "common.name" . ) }}
          {{- with .Values.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          image: {{- include "common.image" . }}
          imagePullPolicy: IfNotPresent
          {{- with .Values.command }}
          command:
            {{ toyaml . | nindent 12}}
          {{- end }}
          {{- with .Values.args: }}
          args:
            {{ toyaml . | nindent 12}}
          {{- end }}
          {{- $env := concat (default (list) $common.env) (default (list) .Values.env) }}
          {{- with $env }}
          env:
            {{- range . }}
            - name: {{ .name | quote }}
              {{- if hasKey . "value" }}
              value {{ .value | quote }}
              {{- else if hasKey . "valueFrom" }}
              valuesFrom:
                {{- toYaml .valueFrom | nindent 16 }}
              {{- end }}
            {{- end }}
          {{ - if or .Values.configMap .values.envFrom }}
          envFrom:
            {{- if .Values.configMap }}
            - configMapRef:
                name: {{- include "common.fullname" . }}
            {{- end }}
            {{-with .Values.envFrom }}
              {{- toyaml . | nindent 14 }}
          {{- end }}
          ports:
          {{ if not .Values.containerPorts }}
            - containerPort: {{ .Values.server.port }}
          {{- else }}
            {{- toyaml .Values.containerPorts | nindent 12 }}
          {{- end }}
          {{- with .Values.livenessProbe }}
          livenessProbe:
            {{- toyaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.readinessProbe }}
          readinessProbe:
            {{- toyaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.startupProbe }}
          startupProbe:
            {{- toyaml . | nindent 12 }}
          {{- end }}
          resources:
            {{- toyaml .Values.resources | nindent 12 }}
          
