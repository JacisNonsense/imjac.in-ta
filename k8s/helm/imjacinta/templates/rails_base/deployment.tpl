{{- define "rails.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ template "rails.fullname" . }}
  labels:
    app: {{ template "rails.name" . }}
    chart: {{ template "imjacinta.chart" . }}
    release: {{ .Release.Name | quote }}
spec:
  selector:
    matchLabels:
      app: {{ template "rails.name" . }}
      release: {{ .Release.Name }}

  template:
    metadata:
      labels:
        app: {{ template "rails.name" . }}
        chart: {{ template "imjacinta.chart" . }}
        release: {{ .Release.Name | quote }}
    spec:
      initContainers:
      - name: {{ template "rails.fullname" . }}-migrate
        args: [bundle, exec, rails, "db:create", "db:migrate"]
        {{ include "rails.container.spec" . | nindent 8 }}
      containers:
      - name: {{ template "rails.fullname" . }}
        args: [bundle, exec, rails, s, "-p", "3000", "-b", "0.0.0.0"]
        ports:
        - containerPort: 3000
        {{ include "rails.container.spec" . | nindent 8 }}
{{- end -}}