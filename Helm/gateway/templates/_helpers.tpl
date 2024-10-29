{{- define "gatewayconfig" -}}
checksum/config: {{ include (print $.Template.BasePath "/config/mt3gateway-cm.yaml") . | sha256sum }}
{{- end -}}   

{{- define "gatewaydapr" -}}
{{- if .Capabilities.APIVersions.Has "dapr.io/v1alpha1" }}
dapr.io/enabled: "true"        
dapr.io/app-port: "8080"
dapr.io/log-level: "debug"
dapr.io/http-max-request-size: "16"
dapr.io/app-max-concurrency: "1" 
{{- end -}}   
{{- end -}}   