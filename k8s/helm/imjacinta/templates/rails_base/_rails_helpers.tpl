{{- define "rails.fullname" -}}
{{- template "imjacinta.fullname" . -}}-{{- .name -}}
{{- end -}}

{{- define "rails.name" -}}
{{- template "imjacinta.name" . -}}-{{- .name -}}
{{- end -}}

{{- define "rails.container.spec" -}}
image: {{ .valspec.image.name }}:{{ .valspec.image.tag }}
envFrom:
- configMapRef:
    name: {{ template "imjacinta.fullname" . }}
env:
- name: SECRET_KEY_BASE
  value: abcdefg
- name: RAILS_MASTER_KEY
  value: the_master_key
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-{{ .Values.db.secret.name }}
      key: {{ .Values.db.secret.key }}
{{- with .valspec.container }}
{{- toYaml . | nindent 0 }}
{{- end -}}
{{- end -}}