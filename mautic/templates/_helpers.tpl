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
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "mautic.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}


{{/*
Selector labels
These must not change after deployment.
*/}}
{{- define "mautic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mautic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "mautic.labels" -}}
helm.sh/chart: {{ include "mautic.chart" . }}
{{ include "mautic.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Chart label
*/}}
{{- define "mautic.chart" -}}
{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}
{{/*
Create the service account name
*/}}
{{- define "mautic.serviceAccountName" -}}
{{- if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name }}
{{- else }}
{{- include "mautic.fullname" . }}
{{- end }}
{{- end }}

{{/*
PVC names
*/}}

{{- define "mautic.mediaPVC" -}}
{{- if .Values.persistence.mediaClaim -}}
{{ .Values.persistence.mediaClaim }}
{{- else -}}
{{ include "mautic.fullname" . }}-media
{{- end -}}
{{- end -}}


{{- define "mautic.configPVC" -}}
{{- if .Values.persistence.configClaim -}}
{{ .Values.persistence.configClaim }}
{{- else -}}
{{ include "mautic.fullname" . }}-config
{{- end -}}
{{- end -}}


{{- define "mautic.dataPVC" -}}
{{- if .Values.persistence.dataClaim -}}
{{ .Values.persistence.dataClaim }}
{{- else -}}
{{ include "mautic.fullname" . }}-data
{{- end -}}
{{- end -}}