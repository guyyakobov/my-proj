{{- define "common.deployment" -}}
{{- $common := .Values.common | default (dict) }}
{{- $hpaEnabled := dig "hpa" "enabled" false .Values }}
{{- $deploymentAnnotations := (mergeOverwrite (deepCopy (default (dict) $common.annotations)) (default (dict) .Values.deploymentAnnotations)) }}
{{- $podAnnotations := (mergeOverwrite (deepCopy (default (dict) $common.annotations)) (default (dict) .Values.podAnnotations)) }}
{{- $configMapRollout := and .Values.configMap .Values.configMapRollout }}
{{- $env := include "common.mergeOverwriteListByKey" (dict "lists" (list (default (list) $common.env) (default (list) .Values.env)) "key" "name") | fromYamlArray }}
{{- $volumeMounts := include "common.mergeOverwriteListByKey" (dict "lists" (list (default (list) $common.volumeMounts) (default (list) .Values.volumeMounts)) "key" "name") | fromYamlArray }}
{{- $volumes := include "common.mergeOverwriteListByKey" (dict "lists" (list (default (list) $common.volumes) (default (list) .Values.volumes)) "key" "name") | fromYamlArray }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with  $deploymentAnnotations }}
  annotations:
    {{- include "common.renderStringMap" . | nindent 4 }}
  {{- end }}
spec:
  {{- if not $hpaEnabled }}
  replicas: {{ dig "replicas" 1 .Values }}
  {{- end }}
  revisionHistoryLimit: {{ dig "revisionHistoryLimit" 3 .Values }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  {{- with .Values.updateStrategy }}
  updateStrategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  template:
    metadata:
      labels:
        {{- include "common.labels" . | nindent 8 }}
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
          image: {{ include "common.image" (dict "root" . "image" .Values.image) }}
          imagePullPolicy: IfNotPresent
          {{- with .Values.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $env }}
          env:
            {{- range . }}
            - name: {{ .name | quote }}
              {{- if hasKey . "value" }}
              value: {{ .value | quote }}
              {{- else if hasKey . "valueFrom" }}
              valueFrom:
                {{- toYaml .valueFrom | nindent 16 }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if or .Values.configMap .Values.envFrom }}
          envFrom:
            {{- if .Values.configMap }}
            - configMapRef:
                name: {{ include "common.fullname" . }}
            {{- end }}
            {{- with .Values.envFrom }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          {{- end }}
          ports:
            {{ if not .Values.containerPorts }}
            - containerPort: {{ .Values.server.port }}
            {{- else }}
            {{- toYaml .Values.containerPorts | nindent 12 }}
            {{- end }}
          {{- with .Values.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.startupProbe }}
          startupProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- with $volumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}
        {{- with .Values.extraContainers }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with $volumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{-  end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.schedulerName }}
      schedulerName: {{ . | quote }}
      {{- end }}
{{- end }}