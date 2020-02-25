{{- define "rails.ingress" -}}
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: {{ template "rails.fullname" . }}

spec:
  entryPoints:
    - web
  routes:
  - match: {{ .valspec.ingress.rule }}
    kind: Rule
    priority: {{ default 0 .valspec.ingress.priority }}
    services:
    - name: {{ template "rails.fullname" . }}
      port: 3000
{{- end -}}