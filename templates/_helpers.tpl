{{/*
Expand the name of the chart.
*/}}
{{- define "paperclip.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "paperclip.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "paperclip.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "paperclip.labels" -}}
helm.sh/chart: {{ include "paperclip.chart" . }}
{{ include "paperclip.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "paperclip.selectorLabels" -}}
app.kubernetes.io/name: {{ include "paperclip.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name.
*/}}
{{- define "paperclip.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "paperclip.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image tag — defaults to Chart.AppVersion if image.tag is empty.
*/}}
{{- define "paperclip.imageTag" -}}
{{- default .Chart.AppVersion .Values.image.tag }}
{{- end }}

{{/*
Secret name for auth credentials.
*/}}
{{- define "paperclip.secretName" -}}
{{- if .Values.auth.existingSecret }}
{{- .Values.auth.existingSecret }}
{{- else }}
{{- include "paperclip.fullname" . }}
{{- end }}
{{- end }}

{{/*
PostgreSQL fully qualified name.
*/}}
{{- define "paperclip.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "paperclip.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
DATABASE_URL value — external > in-cluster postgres > empty (embedded PGlite).
*/}}
{{- define "paperclip.databaseUrl" -}}
{{- if .Values.externalDatabase.url }}
{{- .Values.externalDatabase.url }}
{{- else if .Values.postgresql.enabled }}
{{- printf "postgres://%s:%s@%s:5432/%s" .Values.postgresql.auth.username .Values.postgresql.auth.password (include "paperclip.postgresql.fullname" .) .Values.postgresql.auth.database }}
{{- end }}
{{- end }}
