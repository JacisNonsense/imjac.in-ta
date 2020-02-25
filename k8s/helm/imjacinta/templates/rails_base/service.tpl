{{- define "rails.service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ template "rails.fullname" . }}
spec:
  ports:
  - port: 3000
  selector:
    app: {{ template "rails.name" . }}
    release: {{ .Release.Name | quote }}
  type: ClusterIP
{{- end -}}