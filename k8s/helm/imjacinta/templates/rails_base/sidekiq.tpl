{{- define "rails.sidekiq" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "rails.fullname" . }}-sidekiq
  labels:
    app: {{ template "rails.name" . }}-sidekiq
    chart: {{ template "imjacinta.chart" . }}
    release: {{ .Release.Name | quote }}
spec:
  selector:
    matchLabels:
      app: {{ template "rails.name" . }}-sidekiq
      release: {{ .Release.Name }}

  template:
    metadata:
      labels:
        app: {{ template "rails.name" . }}-sidekiq
        chart: {{ template "imjacinta.chart" . }}
        release: {{ .Release.Name | quote }}
    spec:
      containers:
      - name: {{ template "rails.fullname" . }}-sidekiq
        args: [bundle, exec, sidekiq]
        resources:
          {{ toYaml .valspec.sidekiq.resources | nindent 10 }}
        {{ include "rails.container.spec" . | nindent 8 }}
{{- end -}}