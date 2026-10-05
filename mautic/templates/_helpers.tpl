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

{{/*
Subchart secret names (created by the Bitnami MariaDB/Redis charts)
*/}}
{{- define "mautic.mariadbSecretName" -}}
{{- .Values.mariadb.auth.existingSecret | default (printf "%s-mariadb" .Release.Name) -}}
{{- end -}}

{{- define "mautic.redisSecretName" -}}
{{- .Values.redis.auth.existingSecret | default (printf "%s-redis" .Release.Name) -}}
{{- end -}}

{{- define "mautic.redisHost" -}}
{{- printf "%s-redis-master" .Release.Name -}}
{{- end -}}


{{/*
Credential env vars, read from the subchart secrets.
Must come before any env var that references them with $(VAR).
*/}}
{{- define "mautic.secretEnv" -}}
- name: MAUTIC_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "mautic.mariadbSecretName" . }}
      key: mariadb-password
- name: MAUTIC_REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "mautic.redisSecretName" . }}
      key: {{ .Values.redis.auth.existingSecretPasswordKey | default "redis-password" }}
- name: MAUTIC_REDIS_DSN
  value: "redis://:$(MAUTIC_REDIS_PASSWORD)@{{ include "mautic.redisHost" . }}:6379"
- name: MAUTIC_CACHE_ADAPTER_REDIS
  value: '{"adapter":"cache.adapter.redis","dsn":"redis://:$(MAUTIC_REDIS_PASSWORD)@{{ include "mautic.redisHost" . }}:6379"}'
{{- end -}}
