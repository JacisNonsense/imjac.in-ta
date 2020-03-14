{{- define "rails.secret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ template "rails.fullname" . }}
  labels:
    app: {{ template "rails.name" . }}
    chart: {{ template "imjacinta.chart" . }}
    release: {{ .Release.Name | quote }}
type: Opaque
data:
  secret_key_base: {{ .Values.secret_key_base | b64enc | quote }}
  master_key: {{ .valspec.master_key | b64enc | quote }}
  gcs_creds_json: {{ .valspec.gcs | quote }}
  mailer_apikey: {{ .Values.mailer_apikey | b64enc | quote }}
{{- end -}}