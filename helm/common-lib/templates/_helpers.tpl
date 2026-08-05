{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "common.rawName" -}}
{{- default .Chart.Name .Values.nameOverride }}
{{- end }}

{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := include "common.rawName" . }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end }}
{{ include "common.selectorLabels" . }}
{{- with .Values.system }}
app.kubernetes.io/part-of: {{ . }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "common.image" -}}
{{- $ := .root }}
{{- $image := .image }}
{{- $repository := $image.repository | default (printf "%s/%s" $.Values.system (include "common.rawName" $)) -}}
{{- if $image.digest -}}
{{- printf "%s/%s@%s" $image.registry $repository $image.digest -}}
{{- else -}}
{{- printf "%s/%s:%s" $image.registry $repository $image.tag -}}
{{- end -}}
{{- end -}}

{{- define "common.renderStringMap" -}}
{{- range $k, $v := . }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{- end }}

{{- define "common.mergeOverwriteListByKey" -}}
{{- $result := dict }}
{{- $key := required "common.mergeOverwriteListByKey requires key" .key }}
{{- range $list := .lists }}
  {{- range $list }}
    {{- $_ := set $result (toString (index . $key)) . }}
  {{- end }}
{{- end }}
{{- $sorted := list }}
{{- range $name := keys $result | sortAlpha }}
  {{- $sorted = append $sorted (get $result $name) }}
{{- end }}
{{- $sorted | toYaml }}
{{- end }}

{{- define "common.headlessServiceName" -}}
{{- printf "%s-headless" (include "common.fullname" . | trunc 54 | trimSuffix "-") | trunc 63 | trimSuffix "-" }}
{{- end }}