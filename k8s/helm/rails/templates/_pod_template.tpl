{{- define "pod.template.spec.container.rails" -}}
image: "{{ .Values.image.image }}:{{ .Values.image.version }}"
envFrom:
- secretRef:
    name: rails-secrets
- configMapRef:
    name: config
{{ if eq .Values.db true -}}
- secretRef:
    name: db-secrets
{{- end }}
{{ if eq .Values.gcs true -}}
volumeMounts:
- name: gcs
  mountPath: /etc/gcs
  readOnly: true
{{- end }}
{{- with .Values.rails }}
{{- toYaml . | nindent 0 }}
{{- end -}}
{{- end -}}