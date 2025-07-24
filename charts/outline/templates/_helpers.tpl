{{/*
Expand the name of the chart.
*/}}
{{- define "outline.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "outline.fullname" -}}
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
{{- define "outline.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "outline.labels" -}}
helm.sh/chart: {{ include "outline.chart" . }}
{{ include "outline.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "outline.selectorLabels" -}}
app.kubernetes.io/name: {{ include "outline.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Core application environment variables
*/}}
{{- define "outline.coreEnv" -}}
- name: PORT
  value: "3000"
- name: COLLABORATION_URL
  value: ""
{{- if .Values.env.URL }}
- name: URL
  value: {{ .Values.env.URL | quote }}
{{- else if .Values.ingress.tls.enabled }}
- name: URL
  value: "https://{{ .Values.ingress.host }}"
{{- else }}
- name: URL
  value: "http://{{ .Values.ingress.host }}"
- name: FORCE_HTTPS
  value: "false"
{{- end }}
{{- end }}

{{/*
Core secret environment variables (REQUIRED from Kubernetes secret)
*/}}
{{- define "outline.coreSecretEnv" -}}
{{- if .Values.secrets.name }}
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.secretKeyName }}
- name: UTILS_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.utilsSecretName }}
{{- end }}
{{- end }}

{{/*
Database environment variables
*/}}
{{- define "outline.databaseEnv" -}}
{{- $dbHost := ternary (printf "%s-postgresql" .Release.Name) (.Values.postgresql.host | default "localhost") .Values.postgresql.enabled }}
{{- $dbPort := ternary "5432" (.Values.postgresql.port | default "5432" | toString) .Values.postgresql.enabled }}
{{- $dbUser := .Values.postgresql.postgresqlUsername }}
{{- $dbName := .Values.postgresql.postgresqlDatabase }}
{{- if .Values.postgresql.existingSecret }}
- name: DATABASE_URL
  value: "postgres://{{ $dbUser }}:$(POSTGRES_PASSWORD)@{{ $dbHost }}:{{ $dbPort }}/{{ $dbName }}"
- name: DATABASE_URL_TEST
  value: "postgres://{{ $dbUser }}:$(POSTGRES_PASSWORD)@{{ $dbHost }}:{{ $dbPort }}/{{ $dbName }}-test"
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.postgresql.existingSecret }}
      key: {{ .Values.postgresql.existingSecretPasswordKey }}
{{- else }}
- name: DATABASE_URL
  value: "postgres://{{ $dbUser }}:{{ .Values.postgresql.postgresqlPassword }}@{{ $dbHost }}:{{ $dbPort }}/{{ $dbName }}"
- name: DATABASE_URL_TEST
  value: "postgres://{{ $dbUser }}:{{ .Values.postgresql.postgresqlPassword }}@{{ $dbHost }}:{{ $dbPort }}/{{ $dbName }}-test"
{{- end }}
- name: PGSSLMODE
  value: "disable"
{{- end }}

{{/*
Redis environment variables
*/}}
{{- define "outline.redisEnv" -}}
{{- if .Values.redis.enabled }}
- name: REDIS_URL
  value: "redis://{{ .Release.Name }}-redis-master:6379"
{{- else if .Values.env.REDIS_URL }}
- name: REDIS_URL
  value: {{ .Values.env.REDIS_URL }}
{{- else if .Values.env.REDIS_HOST }}
{{- $redisHost := .Values.env.REDIS_HOST }}
{{- $redisPort := .Values.env.REDIS_PORT | default "6379" }}
{{- if .Values.secrets.redisPasswordName }}
- name: REDIS_URL
  value: "redis://$(REDIS_PASSWORD)@{{ $redisHost }}:{{ $redisPort }}"
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.redisPasswordName }}
{{- else }}
- name: REDIS_URL
  value: "redis://{{ $redisHost }}:{{ $redisPort }}"
{{- end }}
{{- end }}
{{- end }}

{{/*
S3/Minio environment variables
*/}}
{{- define "outline.s3Env" -}}
{{- if .Values.minio.enabled }}
{{- if .Values.minio.existingSecret }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.minio.existingSecret }}
      key: {{ .Values.minio.existingSecretAccessKeyKey }}
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.minio.existingSecret }}
      key: {{ .Values.minio.existingSecretSecretKeyKey }}
{{- else }}
- name: AWS_ACCESS_KEY_ID
  value: {{ .Values.minio.accessKey.password | quote }}
- name: AWS_SECRET_ACCESS_KEY
  value: {{ .Values.minio.secretKey.password | quote }}
{{- end }}
- name: AWS_REGION
  value: "us-east-1"
{{- if .Values.minio.ingress.tls }}
- name: AWS_S3_UPLOAD_BUCKET_URL
  value: "https://{{ .Values.minio.ingress.hostname }}"
{{- else }}
- name: AWS_S3_UPLOAD_BUCKET_URL
  value: "http://{{ .Values.minio.ingress.hostname }}"
{{- end }}
- name: AWS_S3_UPLOAD_BUCKET_NAME
  value: {{ .Values.minio.defaultBuckets | quote }}
- name: AWS_S3_UPLOAD_MAX_SIZE
  value: "26214400"
- name: AWS_S3_FORCE_PATH_STYLE
  value: "true"
- name: AWS_3_ACL
  value: "private"
{{- else if .Values.env.AWS_ACCESS_KEY_ID }}
- name: AWS_ACCESS_KEY_ID
  value: {{ .Values.env.AWS_ACCESS_KEY_ID }}
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.awsSecretAccessKey }}
- name: AWS_REGION
  value: {{ .Values.env.AWS_REGION }}
- name: AWS_S3_UPLOAD_BUCKET_URL
  value: {{ .Values.env.AWS_3_UPLOAD_BUCKET_URL }}
- name: AWS_S3_UPLOAD_BUCKET_NAME
  value: {{ .Values.env.AWS_S3_UPLOAD_BUCKET_NAME }}
- name: AWS_S3_UPLOAD_MAX_SIZE
  value: {{ .Values.env.AWS_3_UPLOAD_MAX_SIZE }}
- name: AWS_3_FORCE_PATH_STYLE
  value: {{ .Values.env.AWS_3_FORCE_PATH_STYLE }}
- name: AWS_3_ACL
  value: {{ .Values.env.AWS_3_ACL }}
{{- end }}
{{- end }}

{{/*
Additional environment variables from values.env
Excludes sensitive values that must come from secrets
*/}}
{{- define "outline.additionalEnv" -}}
{{- range $key, $value := .Values.env }}
{{- if not (has $key (list "SLACK_CLIENT_SECRET" "GOOGLE_CLIENT_SECRET" "AZURE_CLIENT_SECRET" "DISCORD_CLIENT_SECRET" "OIDC_CLIENT_SECRET" "SMTP_PASSWORD" "SECRET_KEY" "UTILS_SECRET" "GITHUB_CLIENT_SECRET" "LINEAR_CLIENT_SECRET" "NOTION_CLIENT_SECRET" "GITHUB_WEBHOOK_SECRET" "GITHUB_APP_PRIVATE_KEY" "SLACK_VERIFICATION_TOKEN" "URL")) }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Required secret environment variables from Kubernetes secret
*/}}
{{- define "outline.requiredSecretEnv" -}}
{{- if .Values.env.SLACK_CLIENT_ID }}
- name: SLACK_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.slackClientSecretName }}
{{- end }}
{{- if .Values.env.GOOGLE_CLIENT_ID }}
- name: GOOGLE_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.googleClientSecretName }}
{{- end }}
{{- if .Values.env.AZURE_CLIENT_ID }}
- name: AZURE_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.azureClientSecretName }}
{{- end }}
{{- if .Values.env.DISCORD_CLIENT_ID }}
- name: DISCORD_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.discordClientSecretName }}
{{- end }}
{{- if .Values.env.OIDC_CLIENT_ID }}
- name: OIDC_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.oidcClientSecretName }}
{{- end }}
{{- if .Values.env.SMTP_USERNAME }}
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.smtpPasswordName }}
{{- end }}
{{- if .Values.env.SLACK_VERIFICATION_TOKEN }}
- name: SLACK_VERIFICATION_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.slackVerificationTokenName }}
{{- end }}
{{- if .Values.env.GITHUB_WEBHOOK_SECRET }}
- name: GITHUB_WEBHOOK_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.githubWebhookSecretName }}
{{- end }}
{{- if .Values.env.GITHUB_APP_PRIVATE_KEY }}
- name: GITHUB_APP_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.githubAppPrivateKeyName }}
{{- end }}
{{- if .Values.env.GITHUB_CLIENT_ID }}
- name: GITHUB_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.githubClientSecretName }}
{{- end }}
{{- if .Values.env.LINEAR_CLIENT_ID }}
- name: LINEAR_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.linearClientSecretName }}
{{- end }}
{{- if .Values.env.NOTION_CLIENT_ID }}
- name: NOTION_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.notionClientSecretName }}
{{- end }}
{{- end }}