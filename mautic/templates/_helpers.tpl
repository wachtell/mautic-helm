{{/*
Chart name
*/}}
{{- define "mautic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Full release name
*/}}
{{- define "mautic.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "mautic.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Labels
*/}}
{{- define "mautic.labels" -}}
app.kubernetes.io/name: {{ include "mautic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}