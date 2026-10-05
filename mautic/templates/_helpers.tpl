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
MariaDB Secret (keeps the Bitnami chart's name and keys) and pod labels
*/}}
{{- define "mautic.mariadbSecretName" -}}
{{- .Values.mariadb.auth.existingSecret | default (printf "%s-mariadb" .Release.Name) -}}
{{- end -}}

{{- define "mautic.mariadbSelectorLabels" -}}
app.kubernetes.io/name: {{ include "mautic.name" . }}-mariadb
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
{{- end -}}


{{/*
Credential env vars, read from the MariaDB Secret.
*/}}
{{- define "mautic.secretEnv" -}}
- name: MAUTIC_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "mautic.mariadbSecretName" . }}
      key: mariadb-password
{{- end -}}


{{/*
Per-image-version Symfony cache dir on the shared var/ volume
*/}}
{{- define "mautic.cacheRoot" -}}
/var/www/html/var/cache
{{- end -}}

{{- define "mautic.sessionPath" -}}
/var/www/html/var/sessions
{{- end -}}

{{- define "mautic.cachePath" -}}
{{- printf "%s/%s" (include "mautic.cacheRoot" .) (.Values.image.tag | replace "/" "-") -}}
{{- end -}}


{{/*
Run Mautic console commands as www-data (uid 33 in the official image),
matching the web server, so files written to shared volumes stay writable
*/}}
{{- define "mautic.wwwDataSecurityContext" -}}
runAsUser: 33
runAsGroup: 33
runAsNonRoot: true
{{- end -}}


{{/*
Pod annotations that roll pods when config or credentials change.
The credential Secrets belong to the subcharts, so hash the values that feed them.
*/}}
{{- define "mautic.checksums" -}}
checksum/config: {{ include (print .Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/php-opcache: {{ include (print .Template.BasePath "/php-opcache-configmap.yaml") . | sha256sum }}
checksum/php-session: {{ include (print .Template.BasePath "/php-session-configmap.yaml") . | sha256sum }}
checksum/credentials: {{ .Values.mariadb.auth | toJson | sha256sum }}
{{- end -}}


{{/*
GrapesJS builder assets fetched by the grapesjs-assets job, per Mautic version,
relative to the shared var/ volume
*/}}
{{- define "mautic.grapesjsSubPath" -}}
{{- printf "grapesjs/%s/dist" .Values.grapesjsAssets.version -}}
{{- end -}}


{{/*
Web container start: the image's web entrypoint runs Doctrine migrations on
every start, so with several pods they run concurrently. When the chart runs
them once per upgrade (db-migrate job), drop that block from the entrypoint
and keep everything else (volume/env/DB checks, apache). If upstream changes
the script so the block isn't found, migrations simply keep running as before.
*/}}
{{- define "mautic.webCommand" -}}
- /bin/bash
- -c
- |
  sed -i '/^# run migrations/,/^fi$/d' /entrypoint_mautic_web.sh
  if grep -q 'migrations:migrate' /entrypoint_mautic_web.sh; then
    echo "WARNING: could not disable entrypoint migrations; they will run in this pod" >&2
  else
    echo "Entrypoint migrations disabled (run once per upgrade by the db-migrate job)"
  fi
  exec /entrypoint.sh
{{- end -}}
