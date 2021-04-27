{{- define "rails.ingress" -}}
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: {{ template "rails.fullname" . }}
  labels:
    app: {{ template "rails.name" . }}
    chart: {{ template "imjacinta.chart" . }}
    release: {{ .Release.Name | quote }}

spec:
  entryPoints:
    - websecure
  tls:
    {{- if .Values.traefik.ports.websecure.tls.enabled }}
    certResolver: default
    {{- end }}
  routes:
  - match: {{ .valspec.ingress.rule }}
    kind: Rule
    priority: {{ default 0 .valspec.ingress.priority }}
    services:
    - name: {{ template "rails.fullname" . }}
      port: 3000
    middlewares:
    - name: {{ template "rails.fullname" . }}-internal-404
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: {{ template "rails.fullname" . }}-internal-404
spec:
  replacePathRegex:
    regex: ^/internal/(.*)
    replacement: /404/$1
{{- end -}}
