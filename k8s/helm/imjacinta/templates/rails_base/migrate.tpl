{{- define "rails.migrate" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "rails.fullname" . }}-migrate-job
  labels:
    app: {{ template "rails.name" . }}-migrate-job
    chart: {{ template "imjacinta.chart" . }}
    release: {{ .Release.Name | quote }}
spec:
  backoffLimit: 0
  parallelism: 1
  completions: 1
  ttlSecondsAfterFinished: 10

  # selector:
  #   matchLabels:
  #     app: {{ template "rails.name" . }}-migrate-job
  #     release: {{ .Release.Name | quote }}
  
  template:
    metadata:
      labels:
        app: {{ template "rails.name" . }}-migrate-job
        chart: {{ template "imjacinta.chart" . }}
        release: {{ .Release.Name | quote }}
    spec:
      restartPolicy: Never
      containers:
      - name: {{ template "rails.fullname" . }}-migrate-job
        args: ["bin/rails", "db:create", "db:migrate"]
        {{ include "rails.container.spec" . | nindent 8 }}
{{- end -}}