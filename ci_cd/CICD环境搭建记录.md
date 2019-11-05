# CICD环境搭建记录

## 1 helm 安装

## 2 nginx-ingress安装

```shell
helm install --name kubernetes-nginx-ingress --namespace kube-system --set "rabc.create=true,controller.service.externalIPs[0]=192.168.1.105" aliyun/nginx-ingress
```

## 3 hostpath安装

```shell
#hostpath
helm upgrade --install hostpath-provisioner --namespace kube-system rimusz/hostpath-provisioner

# nfs
helm install stable/nfs-client-provisioner --set nfs.server=192.168.1.105 --set nfs.path=/data/k8s
```

## 4 heapster安装

```shell
helm install --namespace kube-system --name heapster stable/heapster
```

## 5 kubernetes-dashboard安装

```shell
helm install stable/kubernetes-dashboard --name kubernetes-dashboard --namespace kube-system -f values.yaml
```

values.yaml

```yaml
# Default values for kubernetes-dashboard
# This is a YAML-formatted file.
# Declare name/value pairs to be passed into your templates.
# name: value

image:
  repository: k8s.gcr.io/kubernetes-dashboard-amd64
  tag: v1.10.1
  pullPolicy: IfNotPresent
  pullSecrets: []

replicaCount: 1

## Here annotations can be added to the kubernetes dashboard deployment
annotations: {}
## Here labels can be added to the kubernetes dashboard deployment
##
labels: {}
# kubernetes.io/name: "Kubernetes Dashboard"


## Enable possibility to skip login
enableSkipLogin: false

## Serve application over HTTP without TLS
enableInsecureLogin: false

## Additional container arguments
##
# extraArgs:
#   - --enable-skip-login
#   - --enable-insecure-login
#   - --system-banner="Welcome to Kubernetes"

## Additional container environment variables
##
extraEnv: []
# - name: SOME_VAR
#   value: 'some value'

# Annotations to be added to kubernetes dashboard pods
podAnnotations: {}

## Node labels for pod assignment
## Ref: https://kubernetes.io/docs/user-guide/node-selection/
##
nodeSelector: {}

## List of node taints to tolerate (requires Kubernetes >= 1.6)
tolerations: []
#  - key: "key"
#    operator: "Equal|Exists"
#    value: "value"
#    effect: "NoSchedule|PreferNoSchedule|NoExecute"

## Affinity
## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
affinity: {}


service:
  type: ClusterIP
  externalPort: 443

  ## This allows an override of the heapster service name
  ## Default: {{ .Chart.Name }}
  ##
  # nameOverride:

  # LoadBalancerSourcesRange is a list of allowed CIDR values, which are combined with ServicePort to
  # set allowed inbound rules on the security group assigned to the master load balancer
  # loadBalancerSourceRanges: []

  ## Kubernetes Dashboard Service annotations
  ##
  ## For GCE ingress, the following annotation is required:
  ## service.alpha.kubernetes.io/app-protocols: '{"https":"HTTPS"}' if enableInsecureLogin=false
  ## or
  ## service.alpha.kubernetes.io/app-protocols: '{"http":"HTTP"}' if enableInsecureLogin=true
  annotations: {}

  ## Here labels can be added to the Kubernetes Dashboard service
  ##
  labels: {}
  # kubernetes.io/name: "Kubernetes Dashboard"

resources:
  limits:
    cpu: 100m
    memory: 100Mi
  requests:
    cpu: 100m
    memory: 100Mi

ingress:
  ## If true, Kubernetes Dashboard Ingress will be created.
  ##
  enabled: true

  ## Kubernetes Dashboard Ingress annotations
  ##
  ## Add custom labels
  # labels:
  #   key: value
  # annotations:
  #   kubernetes.io/ingress.class: nginx
  #   kubernetes.io/tls-acme: 'true'
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: 'true'
  ## If you plan to use TLS backend with enableInsecureLogin set to false
  ## (default), you need to uncomment the below.
  ## If you use ingress-nginx < 0.21.0
  #   nginx.ingress.kubernetes.io/secure-backends: "true"
    nginx.ingress.kubernetes.io/secure-backends: "true"
  ## if you use ingress-nginx >= 0.21.0
  #   nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"


  ## Kubernetes Dashboard Ingress paths
  ##
  paths:
    - /
  #  - /*

  ## Kubernetes Dashboard Ingress hostnames
  ## Must be provided if Ingress is enabled
  ##
  # hosts:
  #   - kubernetes-dashboard.domain.com

  ## Kubernetes Dashboard Ingress TLS configuration
  ## Secrets must be manually created in the namespace
  ##
  # tls:
  #   - secretName: kubernetes-dashboard-tls
  #     hosts:
  #       - kubernetes-dashboard.domain.com

  tls:
    - secretName: kubernetes-dashboard-tls
      hosts:
        - kubernetes-dashboard.domain.com

rbac:
  # Specifies whether RBAC resources should be created
  create: true

  # Specifies whether cluster-admin ClusterRole will be used for dashboard
  # ServiceAccount (NOT RECOMMENDED).
  clusterAdminRole: true

  # Start in ReadOnly mode.
  # Only dashboard-related Secrets and ConfigMaps will still be available for writing.
  #
  # Turn OFF clusterAdminRole to use clusterReadOnlyRole.
  #
  # The basic idea of the clusterReadOnlyRole comparing to the clusterAdminRole
  # is not to hide all the secrets and sensitive data but more
  # to avoid accidental changes in the cluster outside the standard CI/CD.
  #
  # Same as for clusterAdminRole, it is NOT RECOMMENDED to use this version in production.
  # Instead you should review the role and remove all potentially sensitive parts such as
  # access to persistentvolumes, pods/log etc.
  clusterReadOnlyRole: false

serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name:

livenessProbe:
  # Number of seconds to wait before sending first probe
  initialDelaySeconds: 30
  # Number of seconds to wait for probe response
  timeoutSeconds: 30

podDisruptionBudget:
  # https://kubernetes.io/docs/tasks/run-application/configure-pdb/
  enabled: false
  minAvailable:
  maxUnavailable:

securityContext: {}

networkPolicy: false
```

## 6 安装gitlab-ce

```shell
helm install --namespace kube-system --name kubernetes-gitlab -f gitlab-values.yaml stable/gitlab-ce
```

gitlab-values.yaml

```yaml
## GitLab CE image
## ref: https://hub.docker.com/r/gitlab/gitlab-ce/tags/
##
image: gitlab/gitlab-ce:9.4.1-ce.0

## Specify a imagePullPolicy
## 'Always' if imageTag is 'latest', else set to 'IfNotPresent'
## ref: http://kubernetes.io/docs/user-guide/images/#pre-pulling-images
##
imagePullPolicy: IfNotPresent

## The URL (with protocol) that your users will use to reach the install.
## ref: https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-the-external-url-for-gitlab
##
externalUrl: http://kubernetes-gitlab.domain.com/

## Change the initial default admin password if set. If not set, you'll be
## able to set it when you first visit your install.
##
gitlabRootPassword: "gitlab123"

## For minikube, set this to NodePort, elsewhere use LoadBalancer
## ref: http://kubernetes.io/docs/user-guide/services/#publishing-services---service-types
##
serviceType: ClusterIP

## Ingress configuration options
##
ingress:
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  enabled: false
  tls:
    - secretName: kubernetes-gitlab-tls
      hosts:
        - kubernetes-gitlab.domain.com
  url: kubernetes-gitlab.domain.com

## Configure external service ports
## ref: http://kubernetes.io/docs/user-guide/services/
sshPort: 22
httpPort: 80
httpsPort: 443
## livenessPort Port of liveness probe endpoint
livenessPort: http
## readinessPort Port of readiness probe endpoint
readinessPort: http

## Configure resource requests and limits
## ref: http://kubernetes.io/docs/user-guide/compute-resources/
##
resources:
  ## GitLab requires a good deal of resources. We have split out Postgres and
  ## redis, which helps some. Refer to the guidelines for larger installs.
  ## ref: https://docs.gitlab.com/ce/install/requirements.html#hardware-requirements
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 2Gi
    cpu: 1

## Enable persistence using Persistent Volume Claims
## ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
## ref: https://docs.gitlab.com/ce/install/requirements.html#storage
##
persistence:
  ## This volume persists generated configuration files, keys, and certs.
  ##
  gitlabEtc:
    enabled: true
    size: 1Gi
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    storageClass: hostpath
    accessMode: ReadWriteOnce
  ## This volume is used to store git data and other project files.
  ## ref: https://docs.gitlab.com/omnibus/settings/configuration.html#storing-git-data-in-an-alternative-directory
  ##
  gitlabData:
    enabled: true
    size: 10Gi
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    storageClass: hostpath
    accessMode: ReadWriteOnce

## Configuration values for the postgresql dependency.
## ref: https://github.com/kubernetes/charts/blob/master/stable/postgresql/README.md
##
postgresql:
  # 9.6 is the newest supported version for the GitLab container
  imageTag: "9.6"
  cpu: 1000m
  memory: 1Gi
  postgresUser: gitlab
  postgresPassword: gitlab
  postgresDatabase: gitlab
  persistence:
    size: 10Gi
    storageClass: hostpath
    accessMode: ReadWriteOnce

## Configuration values for the redis dependency.
## ref: https://github.com/kubernetes/charts/blob/master/stable/redis/README.md
##
redis:
  redisPassword: "gitlab"
  resources:
    requests:
      memory: 1Gi
  persistence:
    size: 10Gi
    storageClass: hostpath
    accessMode: ReadWriteOnce
```

gitlab-ingress.yaml

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubernetes-gitlab-ingress
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
spec:
  rules:
  - host: kubernetes-gitlab.domain.com
    http:
      paths:
      - backend:
          serviceName: kubernetes-gitlab-gitlab-ce
          servicePort: 80
        path: /
```

## 7 安装grafana

```shell
helm install stable/grafana --name kubernetes-grafana --namespace kube-system -f grafana-values.yaml
```

grafana-values.yaml

```yaml
rbac:
  create: true
  pspEnabled: true
  pspUseAppArmor: true
  namespaced: false
serviceAccount:
  create: true
  name:
  nameTest:

replicas: 1

## See `kubectl explain deployment.spec.strategy` for more
## ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
deploymentStrategy:
  type: RollingUpdate

readinessProbe:
  httpGet:
    path: /api/health
    port: 3000

livenessProbe:
  httpGet:
    path: /api/health
    port: 3000
  initialDelaySeconds: 60
  timeoutSeconds: 30
  failureThreshold: 10

## Use an alternate scheduler, e.g. "stork".
## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
##
# schedulerName: "default-scheduler"

image:
  repository: grafana/grafana
  tag: 6.2.5
  pullPolicy: IfNotPresent

  ## Optionally specify an array of imagePullSecrets.
  ## Secrets must be manually created in the namespace.
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
  ##
  # pullSecrets:
  #   - myRegistrKeySecretName

testFramework:
  image: "dduportal/bats"
  tag: "0.4.0"
  securityContext: {}

securityContext:
  runAsUser: 472
  fsGroup: 472


extraConfigmapMounts: []
  # - name: certs-configmap
  #   mountPath: /etc/grafana/ssl/
  #   subPath: certificates.crt # (optional)
  #   configMap: certs-configmap
  #   readOnly: true


extraEmptyDirMounts: []
  # - name: provisioning-notifiers
  #   mountPath: /etc/grafana/provisioning/notifiers


## Assign a PriorityClassName to pods if set
# priorityClassName:

downloadDashboardsImage:
  repository: appropriate/curl
  tag: latest
  pullPolicy: IfNotPresent

downloadDashboards:
  env: {}

## Pod Annotations
# podAnnotations: {}

## Deployment annotations
# annotations: {}

## Expose the grafana service to be accessed from outside the cluster (LoadBalancer service).
## or access it from within the cluster (ClusterIP service). Set the service type and the port to serve it.
## ref: http://kubernetes.io/docs/user-guide/services/
##
service:
  type: ClusterIP
  port: 80
  targetPort: 3000
    # targetPort: 4181 To be used with a proxy extraContainer
  annotations: {}
  labels: {}

ingress:
  enabled: true
  annotations: 
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  labels: {}
  path: /
  hosts:
    - kubernetes-grafana.domain.com
  tls:
    - secretName: kubernetes-grafana-tls
      hosts:
        - kubernetes-grafana.domain.com

resources: {}
#  limits:
#    cpu: 100m
#    memory: 128Mi
#  requests:
#    cpu: 100m
#    memory: 128Mi

## Node labels for pod assignment
## ref: https://kubernetes.io/docs/user-guide/node-selection/
#
nodeSelector: {}

## Tolerations for pod assignment
## ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
##
tolerations: []

## Affinity for pod assignment
## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
##
affinity: {}

extraInitContainers: []

## Enable an Specify container in extraContainers. This is meant to allow adding an authentication proxy to a grafana pod
extraContainers: |
# - name: proxy
#   image: quay.io/gambol99/keycloak-proxy:latest
#   args:
#   - -provider=github
#   - -client-id=
#   - -client-secret=
#   - -github-org=<ORG_NAME>
#   - -email-domain=*
#   - -cookie-secret=
#   - -http-address=http://0.0.0.0:4181
#   - -upstream-url=http://127.0.0.1:3000
#   ports:
#     - name: proxy-web
#       containerPort: 4181

## Enable persistence using Persistent Volume Claims
## ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
##
persistence:
  enabled: true
  storageClassName: hostpath
  accessModes:
    - ReadWriteOnce
  size: 10Gi
  # annotations: {}
  finalizers:
    - kubernetes.io/pvc-protection
  # subPath: ""
  # existingClaim:

initChownData:
  ## If false, data ownership will not be reset at startup
  ## This allows the prometheus-server to be run with an arbitrary user
  ##
  enabled: true

  ## initChownData container image
  ##
  image:
    repository: busybox
    tag: "1.30"
    pullPolicy: IfNotPresent

  ## initChownData resource requests and limits
  ## Ref: http://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}
  #  limits:
  #    cpu: 100m
  #    memory: 128Mi
  #  requests:
  #    cpu: 100m
  #    memory: 128Mi


# Administrator credentials when not using an existing secret (see below)
adminUser: admin
adminPassword: caffe

# Use an existing secret for the admin user.
admin:
  existingSecret: ""
  userKey: admin-user
  passwordKey: admin-caffe

## Define command to be executed at startup by grafana container
## Needed if using `vault-env` to manage secrets (ref: https://banzaicloud.com/blog/inject-secrets-into-pods-vault/)
## Default is "run.sh" as defined in grafana's Dockerfile
# command:
# - "sh"
# - "/run.sh"

## Use an alternate scheduler, e.g. "stork".
## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
##
# schedulerName:

## Extra environment variables that will be pass onto deployment pods
env: {}

## The name of a secret in the same kubernetes namespace which contain values to be added to the environment
## This can be useful for auth tokens, etc
envFromSecret: ""

## Additional grafana server secret mounts
# Defines additional mounts with secrets. Secrets must be manually created in the namespace.
extraSecretMounts: []
  # - name: secret-files
  #   mountPath: /etc/secrets
  #   secretName: grafana-secret-files
  #   readOnly: true

## Additional grafana server volume mounts
# Defines additional volume mounts.
extraVolumeMounts: []
  # - name: extra-volume
  #   mountPath: /mnt/volume
  #   readOnly: true
  #   existingClaim: volume-claim

## Pass the plugins you want installed as a list.
##
plugins: []
  # - digrich-bubblechart-panel
  # - grafana-clock-panel

## Configure grafana datasources
## ref: http://docs.grafana.org/administration/provisioning/#datasources
##
datasources: {}
#  datasources.yaml:
#    apiVersion: 1
#    datasources:
#    - name: Prometheus
#      type: prometheus
#      url: http://prometheus-prometheus-server
#      access: proxy
#      isDefault: true

## Configure notifiers
## ref: http://docs.grafana.org/administration/provisioning/#alert-notification-channels
##
notifiers: {}
#  notifiers.yaml:
#    notifiers:
#    - name: email-notifier
#      type: email
#      uid: email1
#      # either:
#      org_id: 1
#      # or
#      org_name: Main Org.
#      is_default: true
#      settings:
#        addresses: an_email_address@example.com
#    delete_notifiers:

## Configure grafana dashboard providers
## ref: http://docs.grafana.org/administration/provisioning/#dashboards
##
## `path` must be /var/lib/grafana/dashboards/<provider_name>
##
dashboardProviders: {}
#  dashboardproviders.yaml:
#    apiVersion: 1
#    providers:
#    - name: 'default'
#      orgId: 1
#      folder: ''
#      type: file
#      disableDeletion: false
#      editable: true
#      options:
#        path: /var/lib/grafana/dashboards/default

## Configure grafana dashboard to import
## NOTE: To use dashboards you must also enable/configure dashboardProviders
## ref: https://grafana.com/dashboards
##
## dashboards per provider, use provider name as key.
##
dashboards: {}
  # default:
  #   some-dashboard:
  #     json: |
  #       $RAW_JSON
  #   custom-dashboard:
  #     file: dashboards/custom-dashboard.json
  #   prometheus-stats:
  #     gnetId: 2
  #     revision: 2
  #     datasource: Prometheus
  #   local-dashboard:
  #     url: https://example.com/repository/test.json
  #   local-dashboard-base64:
  #     url: https://example.com/repository/test-b64.json
  #     b64content: true

## Reference to external ConfigMap per provider. Use provider name as key and ConfiMap name as value.
## A provider dashboards must be defined either by external ConfigMaps or in values.yaml, not in both.
## ConfigMap data example:
##
## data:
##   example-dashboard.json: |
##     RAW_JSON
##
dashboardsConfigMaps: {}
#  default: ""

## Grafana's primary configuration
## NOTE: values in map will be converted to ini format
## ref: http://docs.grafana.org/installation/configuration/
##
grafana.ini:
  paths:
    data: /var/lib/grafana/data
    logs: /var/log/grafana
    plugins: /var/lib/grafana/plugins
    provisioning: /etc/grafana/provisioning
  analytics:
    check_for_updates: true
  log:
    mode: console
  grafana_net:
    url: https://grafana.net
## LDAP Authentication can be enabled with the following values on grafana.ini
## NOTE: Grafana will fail to start if the value for ldap.toml is invalid
  # auth.ldap:
  #   enabled: true
  #   allow_sign_up: true
  #   config_file: /etc/grafana/ldap.toml

## Grafana's LDAP configuration
## Templated by the template in _helpers.tpl
## NOTE: To enable the grafana.ini must be configured with auth.ldap.enabled
## ref: http://docs.grafana.org/installation/configuration/#auth-ldap
## ref: http://docs.grafana.org/installation/ldap/#configuration
ldap:
  # `existingSecret` is a reference to an existing secret containing the ldap configuration
  # for Grafana in a key `ldap-toml`.
  existingSecret: ""
  # `config` is the content of `ldap.toml` that will be stored in the created secret
  config: ""
  # config: |-
  #   verbose_logging = true

  #   [[servers]]
  #   host = "my-ldap-server"
  #   port = 636
  #   use_ssl = true
  #   start_tls = false
  #   ssl_skip_verify = false
  #   bind_dn = "uid=%s,ou=users,dc=myorg,dc=com"

## Grafana's SMTP configuration
## NOTE: To enable, grafana.ini must be configured with smtp.enabled
## ref: http://docs.grafana.org/installation/configuration/#smtp
smtp:
  # `existingSecret` is a reference to an existing secret containing the smtp configuration
  # for Grafana.
  existingSecret: ""
  userKey: "user"
  passwordKey: "password"

## Sidecars that collect the configmaps with specified label and stores the included files them into the respective folders
## Requires at least Grafana 5 to work and can't be used together with parameters dashboardProviders, datasources and dashboards
sidecar:
  image: kiwigrid/k8s-sidecar:0.1.20
  imagePullPolicy: IfNotPresent
  resources: {}
#   limits:
#     cpu: 100m
#     memory: 100Mi
#   requests:
#     cpu: 50m
#     memory: 50Mi
  # skipTlsVerify Set to true to skip tls verification for kube api calls
  # skipTlsVerify: true
  dashboards:
    enabled: false
    # label that the configmaps with dashboards are marked with
    label: grafana_dashboard
    # folder in the pod that should hold the collected dashboards (unless `defaultFolderName` is set)
    folder: /tmp/dashboards
    # The default folder name, it will create a subfolder under the `folder` and put dashboards in there instead
    defaultFolderName: null
    # If specified, the sidecar will search for dashboard config-maps inside this namespace.
    # Otherwise the namespace in which the sidecar is running will be used.
    # It's also possible to specify ALL to search in all namespaces
    searchNamespace: null
    # provider configuration that lets grafana manage the dashboards
    provider:
      # name of the provider, should be unique
      name: sidecarProvider
      # orgid as configured in grafana
      orgid: 1
      # folder in which the dashboards should be imported in grafana
      folder: ''
      # type of the provider
      type: file
      # disableDelete to activate a import-only behaviour
      disableDelete: false
  datasources:
    enabled: false
    # label that the configmaps with datasources are marked with
    label: grafana_datasource
    # If specified, the sidecar will search for datasource config-maps inside this namespace.
    # Otherwise the namespace in which the sidecar is running will be used.
    # It's also possible to specify ALL to search in all namespaces
    searchNamespace: null
```

## 8 安装prometheus

```shell
helm install stable/prometheus --name kubernetes-prometheus --namespace kube-system -f prometheus-values.yaml
```

prometheus-values.yaml

```yaml
rbac:
  create: true

podSecurityPolicy:
  enabled: false

imagePullSecrets:
# - name: "image-pull-secret"

## Define serviceAccount names for components. Defaults to component's fully qualified name.
##
serviceAccounts:
  alertmanager:
    create: true
    name:
  kubeStateMetrics:
    create: true
    name:
  nodeExporter:
    create: true
    name:
  pushgateway:
    create: true
    name:
  server:
    create: true
    name:

alertmanager:
  ## If false, alertmanager will not be installed
  ##
  enabled: true

  ## alertmanager container name
  ##
  name: alertmanager

  ## alertmanager container image
  ##
  image:
    repository: prom/alertmanager
    tag: v0.18.0
    pullPolicy: IfNotPresent

  ## alertmanager priorityClassName
  ##
  priorityClassName: ""

  ## Additional alertmanager container arguments
  ##
  extraArgs: {}

  ## The URL prefix at which the container can be accessed. Useful in the case the '-web.external-url' includes a slug
  ## so that the various internal URLs are still able to access as they are in the default case.
  ## (Optional)
  prefixURL: ""

  ## External URL which can access alertmanager
  ## Maybe same with Ingress host name
  baseURL: "/"

  ## Additional alertmanager container environment variable
  ## For instance to add a http_proxy
  ##
  extraEnv: {}

  ## Additional alertmanager Secret mounts
  # Defines additional mounts with secrets. Secrets must be manually created in the namespace.
  extraSecretMounts: []
    # - name: secret-files
    #   mountPath: /etc/secrets
    #   subPath: ""
    #   secretName: alertmanager-secret-files
    #   readOnly: true

  ## ConfigMap override where fullname is {{.Release.Name}}-{{.Values.alertmanager.configMapOverrideName}}
  ## Defining configMapOverrideName will cause templates/alertmanager-configmap.yaml
  ## to NOT generate a ConfigMap resource
  ##
  configMapOverrideName: ""

  ## The name of a secret in the same kubernetes namespace which contains the Alertmanager config
  ## Defining configFromSecret will cause templates/alertmanager-configmap.yaml
  ## to NOT generate a ConfigMap resource
  ##
  configFromSecret: ""

  ## The configuration file name to be loaded to alertmanager
  ## Must match the key within configuration loaded from ConfigMap/Secret
  ##
  configFileName: alertmanager.yml

  ingress:
    ## If true, alertmanager Ingress will be created
    ##
    enabled: true

    ## alertmanager Ingress annotations
    ##
    annotations: 
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "true"

    ## alertmanager Ingress additional labels
    ##
    extraLabels: {}

    ## alertmanager Ingress hostnames with optional path
    ## Must be provided if Ingress is enabled
    ##
    hosts:
      - kubernetes-prometheus.domain.com
    tls:
      - secretName: kubernetes-prometheus-tls
        hosts:
          - kubernetes-prometheus.domain.com

  ## Alertmanager Deployment Strategy type
  # strategy:
  #   type: Recreate

  ## Node tolerations for alertmanager scheduling to nodes with taints
  ## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
  ##
  tolerations: []
    # - key: "key"
    #   operator: "Equal|Exists"
    #   value: "value"
    #   effect: "NoSchedule|PreferNoSchedule|NoExecute(1.6 only)"

  ## Node labels for alertmanager pod assignment
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector: {}

  ## Pod affinity
  ##
  affinity: {}

  ## Use an alternate scheduler, e.g. "stork".
  ## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
  ##
  # schedulerName:

  persistentVolume:
    ## If true, alertmanager will create/use a Persistent Volume Claim
    ## If false, use emptyDir
    ##
    enabled: true

    ## alertmanager data Persistent Volume access modes
    ## Must match those of existing PV or dynamic provisioner
    ## Ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
    ##
    accessModes:
      - ReadWriteOnce

    ## alertmanager data Persistent Volume Claim annotations
    ##
    annotations: {}

    ## alertmanager data Persistent Volume existing claim name
    ## Requires alertmanager.persistentVolume.enabled: true
    ## If defined, PVC must be created manually before volume will be bound
    existingClaim: ""

    ## alertmanager data Persistent Volume mount root path
    ##
    mountPath: /data

    ## alertmanager data Persistent Volume size
    ##
    size: 2Gi

    ## alertmanager data Persistent Volume Storage Class
    ## If defined, storageClassName: <storageClass>
    ## If set to "-", storageClassName: "", which disables dynamic provisioning
    ## If undefined (the default) or set to null, no storageClassName spec is
    ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
    ##   GKE, AWS & OpenStack)
    ##
    storageClass: hostpath

    ## Subdirectory of alertmanager data Persistent Volume to mount
    ## Useful if the volume's root directory is not empty
    ##
    subPath: ""

  ## Annotations to be added to alertmanager pods
  ##
  podAnnotations: {}

  ## Specify if a Pod Security Policy for node-exporter must be created
  ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/
  ##
  podSecurityPolicy:
    annotations: {}
      ## Specify pod annotations
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#apparmor
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#seccomp
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#sysctl
      ##
      # seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
      # seccomp.security.alpha.kubernetes.io/defaultProfileName: 'docker/default'
      # apparmor.security.beta.kubernetes.io/defaultProfileName: 'runtime/default'

  ## Use a StatefulSet if replicaCount needs to be greater than 1 (see below)
  ##
  replicaCount: 1

  statefulSet:
    ## If true, use a statefulset instead of a deployment for pod management.
    ## This allows to scale replicas to more than 1 pod
    ##
    enabled: false

    podManagementPolicy: OrderedReady

    ## Alertmanager headless service to use for the statefulset
    ##
    headless:
      annotations: {}
      labels: {}

      ## Enabling peer mesh service end points for enabling the HA alert manager
      ## Ref: https://github.com/prometheus/alertmanager/blob/master/README.md
      # enableMeshPeer : true

      servicePort: 80

  ## alertmanager resource requests and limits
  ## Ref: http://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}
    # limits:
    #   cpu: 10m
    #   memory: 32Mi
    # requests:
    #   cpu: 10m
    #   memory: 32Mi

  ## Security context to be added to alertmanager pods
  ##
  securityContext:
    runAsUser: 65534
    runAsNonRoot: true
    runAsGroup: 65534
    fsGroup: 65534

  service:
    annotations: {}
    labels: {}
    clusterIP: ""

    ## Enabling peer mesh service end points for enabling the HA alert manager
    ## Ref: https://github.com/prometheus/alertmanager/blob/master/README.md
    # enableMeshPeer : true

    ## List of IP addresses at which the alertmanager service is available
    ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
    ##
    externalIPs: []

    loadBalancerIP: ""
    loadBalancerSourceRanges: []
    servicePort: 80
    # nodePort: 30000
    type: ClusterIP

## Monitors ConfigMap changes and POSTs to a URL
## Ref: https://github.com/jimmidyson/configmap-reload
##
configmapReload:
  ## configmap-reload container name
  ##
  name: configmap-reload

  ## configmap-reload container image
  ##
  image:
    repository: jimmidyson/configmap-reload
    tag: v0.2.2
    pullPolicy: IfNotPresent

  ## Additional configmap-reload container arguments
  ##
  extraArgs: {}
  ## Additional configmap-reload volume directories
  ##
  extraVolumeDirs: []


  ## Additional configmap-reload mounts
  ##
  extraConfigmapMounts: []
    # - name: prometheus-alerts
    #   mountPath: /etc/alerts.d
    #   subPath: ""
    #   configMap: prometheus-alerts
    #   readOnly: true


  ## configmap-reload resource requests and limits
  ## Ref: http://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}

kubeStateMetrics:
  ## If false, kube-state-metrics will not be installed
  ##
  enabled: true

  ## kube-state-metrics container name
  ##
  name: kube-state-metrics

  ## kube-state-metrics container image
  ##
  image:
    repository: quay.io/coreos/kube-state-metrics
    tag: v1.6.0
    pullPolicy: IfNotPresent

  ## kube-state-metrics priorityClassName
  ##
  priorityClassName: ""

  ## kube-state-metrics container arguments
  ##
  args: {}

  ## Node tolerations for kube-state-metrics scheduling to nodes with taints
  ## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
  ##
  tolerations: []
    # - key: "key"
    #   operator: "Equal|Exists"
    #   value: "value"
    #   effect: "NoSchedule|PreferNoSchedule|NoExecute(1.6 only)"

  ## Node labels for kube-state-metrics pod assignment
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector: {}

  ## Annotations to be added to kube-state-metrics pods
  ##
  podAnnotations: {}

  ## Specify if a Pod Security Policy for node-exporter must be created
  ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/
  ##
  podSecurityPolicy:
    annotations: {}
      ## Specify pod annotations
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#apparmor
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#seccomp
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#sysctl
      ##
      # seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
      # seccomp.security.alpha.kubernetes.io/defaultProfileName: 'docker/default'
      # apparmor.security.beta.kubernetes.io/defaultProfileName: 'runtime/default'

  pod:
    labels: {}

  replicaCount: 1

  ## kube-state-metrics resource requests and limits
  ## Ref: http://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}
    # limits:
    #   cpu: 10m
    #   memory: 16Mi
    # requests:
    #   cpu: 10m
    #   memory: 16Mi

  ## Security context to be added to kube-state-metrics pods
  ##
  securityContext:
    runAsUser: 65534
    runAsNonRoot: true

  service:
    annotations:
      prometheus.io/scrape: "true"
    labels: {}

    # Exposed as a headless service:
    # https://kubernetes.io/docs/concepts/services-networking/service/#headless-services
    clusterIP: None

    ## List of IP addresses at which the kube-state-metrics service is available
    ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
    ##
    externalIPs: []

    loadBalancerIP: ""
    loadBalancerSourceRanges: []
    servicePort: 80
    type: ClusterIP

nodeExporter:
  ## If false, node-exporter will not be installed
  ##
  enabled: true

  ## If true, node-exporter pods share the host network namespace
  ##
  hostNetwork: true

  ## If true, node-exporter pods share the host PID namespace
  ##
  hostPID: true

  ## node-exporter container name
  ##
  name: node-exporter

  ## node-exporter container image
  ##
  image:
    repository: prom/node-exporter
    tag: v0.18.0
    pullPolicy: IfNotPresent

  ## Specify if a Pod Security Policy for node-exporter must be created
  ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/
  ##
  podSecurityPolicy:
    annotations: {}
      ## Specify pod annotations
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#apparmor
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#seccomp
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#sysctl
      ##
      # seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
      # seccomp.security.alpha.kubernetes.io/defaultProfileName: 'docker/default'
      # apparmor.security.beta.kubernetes.io/defaultProfileName: 'runtime/default'

  ## node-exporter priorityClassName
  ##
  priorityClassName: ""

  ## Custom Update Strategy
  ##
  updateStrategy:
    type: RollingUpdate

  ## Additional node-exporter container arguments
  ##
  extraArgs: {}

  ## Additional node-exporter hostPath mounts
  ##
  extraHostPathMounts: []
    # - name: textfile-dir
    #   mountPath: /srv/txt_collector
    #   hostPath: /var/lib/node-exporter
    #   readOnly: true
    #   mountPropagation: HostToContainer

  extraConfigmapMounts: []
    # - name: certs-configmap
    #   mountPath: /prometheus
    #   configMap: certs-configmap
    #   readOnly: true

  ## Node tolerations for node-exporter scheduling to nodes with taints
  ## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
  ##
  tolerations: []
    # - key: "key"
    #   operator: "Equal|Exists"
    #   value: "value"
    #   effect: "NoSchedule|PreferNoSchedule|NoExecute(1.6 only)"

  ## Node labels for node-exporter pod assignment
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector: {}

  ## Annotations to be added to node-exporter pods
  ##
  podAnnotations: {}

  ## Labels to be added to node-exporter pods
  ##
  pod:
    labels: {}

  ## node-exporter resource limits & requests
  ## Ref: https://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}
    # limits:
    #   cpu: 200m
    #   memory: 50Mi
    # requests:
    #   cpu: 100m
    #   memory: 30Mi

  ## Security context to be added to node-exporter pods
  ##
  securityContext: {}
    # runAsUser: 0

  service:
    annotations:
      prometheus.io/scrape: "true"
    labels: {}

    # Exposed as a headless service:
    # https://kubernetes.io/docs/concepts/services-networking/service/#headless-services
    clusterIP: None

    ## List of IP addresses at which the node-exporter service is available
    ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
    ##
    externalIPs: []

    hostPort: 9100
    loadBalancerIP: ""
    loadBalancerSourceRanges: []
    servicePort: 9100
    type: ClusterIP

server:
  ## Prometheus server container name
  ##
  enabled: true
  name: server
  sidecarContainers:

  ## Prometheus server container image
  ##
  image:
    repository: prom/prometheus
    tag: v2.11.1
    pullPolicy: IfNotPresent

  ## prometheus server priorityClassName
  ##
  priorityClassName: ""

  ## The URL prefix at which the container can be accessed. Useful in the case the '-web.external-url' includes a slug
  ## so that the various internal URLs are still able to access as they are in the default case.
  ## (Optional)
  prefixURL: ""

  ## External URL which can access alertmanager
  ## Maybe same with Ingress host name
  baseURL: ""

  ## Additional server container environment variables
  ##
  ## You specify this manually like you would a raw deployment manifest.
  ## This means you can bind in environment variables from secrets.
  ##
  ## e.g. static environment variable:
  ##  - name: DEMO_GREETING
  ##    value: "Hello from the environment"
  ##
  ## e.g. secret environment variable:
  ## - name: USERNAME
  ##   valueFrom:
  ##     secretKeyRef:
  ##       name: mysecret
  ##       key: username
  env: {}

  ## This flag controls access to the administrative HTTP API which includes functionality such as deleting time
  ## series. This is disabled by default.
  enableAdminApi: false

  ## This flag controls BD locking
  skipTSDBLock: false

  ## Path to a configuration file on prometheus server container FS
  configPath: /etc/config/prometheus.yml

  global:
    ## How frequently to scrape targets by default
    ##
    scrape_interval: 1m
    ## How long until a scrape request times out
    ##
    scrape_timeout: 10s
    ## How frequently to evaluate rules
    ##
    evaluation_interval: 1m

  ## Additional Prometheus server container arguments
  ##
  extraArgs: {}

  ## Additional Prometheus server Volume mounts
  ##
  extraVolumeMounts: []

  ## Additional Prometheus server Volumes
  ##
  extraVolumes: []

  ## Additional Prometheus server hostPath mounts
  ##
  extraHostPathMounts: []
    # - name: certs-dir
    #   mountPath: /etc/kubernetes/certs
    #   subPath: ""
    #   hostPath: /etc/kubernetes/certs
    #   readOnly: true

  extraConfigmapMounts: []
    # - name: certs-configmap
    #   mountPath: /prometheus
    #   subPath: ""
    #   configMap: certs-configmap
    #   readOnly: true

  ## Additional Prometheus server Secret mounts
  # Defines additional mounts with secrets. Secrets must be manually created in the namespace.
  extraSecretMounts: []
    # - name: secret-files
    #   mountPath: /etc/secrets
    #   subPath: ""
    #   secretName: prom-secret-files
    #   readOnly: true

  ## ConfigMap override where fullname is {{.Release.Name}}-{{.Values.server.configMapOverrideName}}
  ## Defining configMapOverrideName will cause templates/server-configmap.yaml
  ## to NOT generate a ConfigMap resource
  ##
  configMapOverrideName: ""

  ingress:
    ## If true, Prometheus server Ingress will be created
    ##
    enabled: false

    ## Prometheus server Ingress annotations
    ##
    annotations: {}
    #   kubernetes.io/ingress.class: nginx
    #   kubernetes.io/tls-acme: 'true'

    ## Prometheus server Ingress additional labels
    ##
    extraLabels: {}

    ## Prometheus server Ingress hostnames with optional path
    ## Must be provided if Ingress is enabled
    ##
    hosts: []
    #   - prometheus.domain.com
    #   - domain.com/prometheus

    ## Prometheus server Ingress TLS configuration
    ## Secrets must be manually created in the namespace
    ##
    tls: []
    #   - secretName: prometheus-server-tls
    #     hosts:
    #       - prometheus.domain.com

  ## Server Deployment Strategy type
  # strategy:
  #   type: Recreate

  ## Node tolerations for server scheduling to nodes with taints
  ## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
  ##
  tolerations: []
    # - key: "key"
    #   operator: "Equal|Exists"
    #   value: "value"
    #   effect: "NoSchedule|PreferNoSchedule|NoExecute(1.6 only)"

  ## Node labels for Prometheus server pod assignment
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector: {}

  ## Pod affinity
  ##
  affinity: {}

  ## Use an alternate scheduler, e.g. "stork".
  ## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
  ##
  # schedulerName:

  persistentVolume:
    ## If true, Prometheus server will create/use a Persistent Volume Claim
    ## If false, use emptyDir
    ##
    enabled: true

    ## Prometheus server data Persistent Volume access modes
    ## Must match those of existing PV or dynamic provisioner
    ## Ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
    ##
    accessModes:
      - ReadWriteOnce

    ## Prometheus server data Persistent Volume annotations
    ##
    annotations: {}

    ## Prometheus server data Persistent Volume existing claim name
    ## Requires server.persistentVolume.enabled: true
    ## If defined, PVC must be created manually before volume will be bound
    existingClaim: ""

    ## Prometheus server data Persistent Volume mount root path
    ##
    mountPath: /data

    ## Prometheus server data Persistent Volume size
    ##
    size: 8Gi

    ## Prometheus server data Persistent Volume Storage Class
    ## If defined, storageClassName: <storageClass>
    ## If set to "-", storageClassName: "", which disables dynamic provisioning
    ## If undefined (the default) or set to null, no storageClassName spec is
    ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
    ##   GKE, AWS & OpenStack)
    ##
    storageClass: hostpath

    ## Subdirectory of Prometheus server data Persistent Volume to mount
    ## Useful if the volume's root directory is not empty
    ##
    subPath: ""

  emptyDir:
    sizeLimit: ""

  ## Annotations to be added to Prometheus server pods
  ##
  podAnnotations: {}
    # iam.amazonaws.com/role: prometheus

  ## Labels to be added to Prometheus server pods
  ##
  podLabels: {}

  ## Specify if a Pod Security Policy for node-exporter must be created
  ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/
  ##
  podSecurityPolicy:
    annotations: {}
      ## Specify pod annotations
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#apparmor
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#seccomp
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#sysctl
      ##
      # seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
      # seccomp.security.alpha.kubernetes.io/defaultProfileName: 'docker/default'
      # apparmor.security.beta.kubernetes.io/defaultProfileName: 'runtime/default'

  ## Use a StatefulSet if replicaCount needs to be greater than 1 (see below)
  ##
  replicaCount: 1

  statefulSet:
    ## If true, use a statefulset instead of a deployment for pod management.
    ## This allows to scale replicas to more than 1 pod
    ##
    enabled: false

    annotations: {}
    labels: {}
    podManagementPolicy: OrderedReady

    ## Alertmanager headless service to use for the statefulset
    ##
    headless:
      annotations: {}
      labels: {}
      servicePort: 80

  ## Prometheus server resource requests and limits
  ## Ref: http://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}
    # limits:
    #   cpu: 500m
    #   memory: 512Mi
    # requests:
    #   cpu: 500m
    #   memory: 512Mi

  ## Security context to be added to server pods
  ##
  securityContext:
    runAsUser: 65534
    runAsNonRoot: true
    runAsGroup: 65534
    fsGroup: 65534

  service:
    annotations: {}
    labels: {}
    clusterIP: ""

    ## List of IP addresses at which the Prometheus server service is available
    ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
    ##
    externalIPs: []

    loadBalancerIP: ""
    loadBalancerSourceRanges: []
    servicePort: 80
    type: ClusterIP

  ## Prometheus server pod termination grace period
  ##
  terminationGracePeriodSeconds: 300

  ## Prometheus data retention period (default if not specified is 15 days)
  ##
  retention: "15d"

pushgateway:
  ## If false, pushgateway will not be installed
  ##
  enabled: true

  ## Use an alternate scheduler, e.g. "stork".
  ## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
  ##
  # schedulerName:

  ## pushgateway container name
  ##
  name: pushgateway

  ## pushgateway container image
  ##
  image:
    repository: prom/pushgateway
    tag: v0.8.0
    pullPolicy: IfNotPresent

  ## pushgateway priorityClassName
  ##
  priorityClassName: ""

  ## Additional pushgateway container arguments
  ##
  ## for example: persistence.file: /data/pushgateway.data
  extraArgs: {}

  ingress:
    ## If true, pushgateway Ingress will be created
    ##
    enabled: false

    ## pushgateway Ingress annotations
    ##
    annotations: {}
    #   kubernetes.io/ingress.class: nginx
    #   kubernetes.io/tls-acme: 'true'

    ## pushgateway Ingress hostnames with optional path
    ## Must be provided if Ingress is enabled
    ##
    hosts: []
    #   - pushgateway.domain.com
    #   - domain.com/pushgateway

    ## pushgateway Ingress TLS configuration
    ## Secrets must be manually created in the namespace
    ##
    tls: []
    #   - secretName: prometheus-alerts-tls
    #     hosts:
    #       - pushgateway.domain.com

  ## Node tolerations for pushgateway scheduling to nodes with taints
  ## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
  ##
  tolerations: []
    # - key: "key"
    #   operator: "Equal|Exists"
    #   value: "value"
    #   effect: "NoSchedule|PreferNoSchedule|NoExecute(1.6 only)"

  ## Node labels for pushgateway pod assignment
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector: {}

  ## Annotations to be added to pushgateway pods
  ##
  podAnnotations: {}

  ## Specify if a Pod Security Policy for node-exporter must be created
  ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/
  ##
  podSecurityPolicy:
    annotations: {}
      ## Specify pod annotations
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#apparmor
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#seccomp
      ## Ref: https://kubernetes.io/docs/concepts/policy/pod-security-policy/#sysctl
      ##
      # seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
      # seccomp.security.alpha.kubernetes.io/defaultProfileName: 'docker/default'
      # apparmor.security.beta.kubernetes.io/defaultProfileName: 'runtime/default'

  replicaCount: 1

  ## pushgateway resource requests and limits
  ## Ref: http://kubernetes.io/docs/user-guide/compute-resources/
  ##
  resources: {}
    # limits:
    #   cpu: 10m
    #   memory: 32Mi
    # requests:
    #   cpu: 10m
    #   memory: 32Mi

  ## Security context to be added to push-gateway pods
  ##
  securityContext:
    runAsUser: 65534
    runAsNonRoot: true

  service:
    annotations:
      prometheus.io/probe: pushgateway
    labels: {}
    clusterIP: ""

    ## List of IP addresses at which the pushgateway service is available
    ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
    ##
    externalIPs: []

    loadBalancerIP: ""
    loadBalancerSourceRanges: []
    servicePort: 9091
    type: ClusterIP

  persistentVolume:
    ## If true, pushgateway will create/use a Persistent Volume Claim
    ## If false, use emptyDir
    ##
    enabled: true

    ## pushgateway data Persistent Volume access modes
    ## Must match those of existing PV or dynamic provisioner
    ## Ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
    ##
    accessModes:
      - ReadWriteOnce

    ## pushgateway data Persistent Volume Claim annotations
    ##
    annotations: {}

    ## pushgateway data Persistent Volume existing claim name
    ## Requires pushgateway.persistentVolume.enabled: true
    ## If defined, PVC must be created manually before volume will be bound
    existingClaim: ""

    ## pushgateway data Persistent Volume mount root path
    ##
    mountPath: /data

    ## pushgateway data Persistent Volume size
    ##
    size: 2Gi

    ## alertmanager data Persistent Volume Storage Class
    ## If defined, storageClassName: <storageClass>
    ## If set to "-", storageClassName: "", which disables dynamic provisioning
    ## If undefined (the default) or set to null, no storageClassName spec is
    ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
    ##   GKE, AWS & OpenStack)
    ##
    storageClass: hostpath

    ## Subdirectory of alertmanager data Persistent Volume to mount
    ## Useful if the volume's root directory is not empty
    ##
    subPath: ""


## alertmanager ConfigMap entries
##
alertmanagerFiles:
  alertmanager.yml:
    global: {}
      # slack_api_url: ''

    receivers:
      - name: default-receiver
        # slack_configs:
        #  - channel: '@you'
        #    send_resolved: true

    route:
      group_wait: 10s
      group_interval: 5m
      receiver: default-receiver
      repeat_interval: 3h

## Prometheus server ConfigMap entries
##
serverFiles:

  ## Alerts configuration
  ## Ref: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
  alerts: {}
  # groups:
  #   - name: Instances
  #     rules:
  #       - alert: InstanceDown
  #         expr: up == 0
  #         for: 5m
  #         labels:
  #           severity: page
  #         annotations:
  #           description: '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes.'
  #           summary: 'Instance {{ $labels.instance }} down'

  rules: {}

  prometheus.yml:
    rule_files:
      - /etc/config/rules
      - /etc/config/alerts

    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets:
            - localhost:9090

      # A scrape configuration for running Prometheus on a Kubernetes cluster.
      # This uses separate scrape configs for cluster components (i.e. API server, node)
      # and services to allow each to use different authentication configs.
      #
      # Kubernetes labels will be added as Prometheus labels on metrics via the
      # `labelmap` relabeling action.

      # Scrape config for API servers.
      #
      # Kubernetes exposes API servers as endpoints to the default/kubernetes
      # service so this uses `endpoints` role and uses relabelling to only keep
      # the endpoints associated with the default/kubernetes service using the
      # default named port `https`. This works for single API server deployments as
      # well as HA API server deployments.
      - job_name: 'kubernetes-apiservers'

        kubernetes_sd_configs:
          - role: endpoints

        # Default to scraping over https. If required, just disable this or change to
        # `http`.
        scheme: https

        # This TLS & bearer token file config is used to connect to the actual scrape
        # endpoints for cluster components. This is separate to discovery auth
        # configuration because discovery & scraping are two separate concerns in
        # Prometheus. The discovery auth config is automatic if Prometheus runs inside
        # the cluster. Otherwise, more config options have to be provided within the
        # <kubernetes_sd_config>.
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          # If your node certificates are self-signed or use a different CA to the
          # master CA, then disable certificate verification below. Note that
          # certificate verification is an integral part of a secure infrastructure
          # so this should only be disabled in a controlled environment. You can
          # disable certificate verification by uncommenting the line below.
          #
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

        # Keep only the default/kubernetes service endpoints for the https port. This
        # will add targets for each API server which Kubernetes adds an endpoint to
        # the default/kubernetes service.
        relabel_configs:
          - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
            action: keep
            regex: default;kubernetes;https

      - job_name: 'kubernetes-nodes'

        # Default to scraping over https. If required, just disable this or change to
        # `http`.
        scheme: https

        # This TLS & bearer token file config is used to connect to the actual scrape
        # endpoints for cluster components. This is separate to discovery auth
        # configuration because discovery & scraping are two separate concerns in
        # Prometheus. The discovery auth config is automatic if Prometheus runs inside
        # the cluster. Otherwise, more config options have to be provided within the
        # <kubernetes_sd_config>.
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          # If your node certificates are self-signed or use a different CA to the
          # master CA, then disable certificate verification below. Note that
          # certificate verification is an integral part of a secure infrastructure
          # so this should only be disabled in a controlled environment. You can
          # disable certificate verification by uncommenting the line below.
          #
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

        kubernetes_sd_configs:
          - role: node

        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - target_label: __address__
            replacement: kubernetes.default.svc:443
          - source_labels: [__meta_kubernetes_node_name]
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/$1/proxy/metrics


      - job_name: 'kubernetes-nodes-cadvisor'

        # Default to scraping over https. If required, just disable this or change to
        # `http`.
        scheme: https

        # This TLS & bearer token file config is used to connect to the actual scrape
        # endpoints for cluster components. This is separate to discovery auth
        # configuration because discovery & scraping are two separate concerns in
        # Prometheus. The discovery auth config is automatic if Prometheus runs inside
        # the cluster. Otherwise, more config options have to be provided within the
        # <kubernetes_sd_config>.
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          # If your node certificates are self-signed or use a different CA to the
          # master CA, then disable certificate verification below. Note that
          # certificate verification is an integral part of a secure infrastructure
          # so this should only be disabled in a controlled environment. You can
          # disable certificate verification by uncommenting the line below.
          #
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

        kubernetes_sd_configs:
          - role: node

        # This configuration will work only on kubelet 1.7.3+
        # As the scrape endpoints for cAdvisor have changed
        # if you are using older version you need to change the replacement to
        # replacement: /api/v1/nodes/$1:4194/proxy/metrics
        # more info here https://github.com/coreos/prometheus-operator/issues/633
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - target_label: __address__
            replacement: kubernetes.default.svc:443
          - source_labels: [__meta_kubernetes_node_name]
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor

      # Scrape config for service endpoints.
      #
      # The relabeling allows the actual service scrape endpoint to be configured
      # via the following annotations:
      #
      # * `prometheus.io/scrape`: Only scrape services that have a value of `true`
      # * `prometheus.io/scheme`: If the metrics endpoint is secured then you will need
      # to set this to `https` & most likely set the `tls_config` of the scrape config.
      # * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
      # * `prometheus.io/port`: If the metrics are exposed on a different port to the
      # service then set this appropriately.
      - job_name: 'kubernetes-service-endpoints'

        kubernetes_sd_configs:
          - role: endpoints

        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
            action: replace
            target_label: __scheme__
            regex: (https?)
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
            action: replace
            target_label: __address__
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            action: replace
            target_label: kubernetes_name
          - source_labels: [__meta_kubernetes_pod_node_name]
            action: replace
            target_label: kubernetes_node

      - job_name: 'prometheus-pushgateway'
        honor_labels: true

        kubernetes_sd_configs:
          - role: service

        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_probe]
            action: keep
            regex: pushgateway

      # Example scrape config for probing services via the Blackbox Exporter.
      #
      # The relabeling allows the actual service scrape endpoint to be configured
      # via the following annotations:
      #
      # * `prometheus.io/probe`: Only probe services that have a value of `true`
      - job_name: 'kubernetes-services'

        metrics_path: /probe
        params:
          module: [http_2xx]

        kubernetes_sd_configs:
          - role: service

        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_probe]
            action: keep
            regex: true
          - source_labels: [__address__]
            target_label: __param_target
          - target_label: __address__
            replacement: blackbox
          - source_labels: [__param_target]
            target_label: instance
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            target_label: kubernetes_name

      # Example scrape config for pods
      #
      # The relabeling allows the actual pod scrape endpoint to be configured via the
      # following annotations:
      #
      # * `prometheus.io/scrape`: Only scrape pods that have a value of `true`
      # * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
      # * `prometheus.io/port`: Scrape the pod on the indicated port instead of the default of `9102`.
      - job_name: 'kubernetes-pods'

        kubernetes_sd_configs:
          - role: pod

        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__
          - action: labelmap
            regex: __meta_kubernetes_pod_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name

# adds additional scrape configs to prometheus.yml
# must be a string so you have to add a | after extraScrapeConfigs:
# example adds prometheus-blackbox-exporter scrape config
extraScrapeConfigs:
  # - job_name: 'prometheus-blackbox-exporter'
  #   metrics_path: /probe
  #   params:
  #     module: [http_2xx]
  #   static_configs:
  #     - targets:
  #       - https://example.com
  #   relabel_configs:
  #     - source_labels: [__address__]
  #       target_label: __param_target
  #     - source_labels: [__param_target]
  #       target_label: instance
  #     - target_label: __address__
  #       replacement: prometheus-blackbox-exporter:9115

networkPolicy:
  ## Enable creation of NetworkPolicy resources.
  ##
  enabled: false
```

## 9 安装jenkins

```shell
helm install --namespace kube-system stable/jenkins --name kubernetes-jenkins -f values.yaml 
```

values.yaml

```yaml
# Default values for jenkins.
# This is a YAML-formatted file.
# Declare name/value pairs to be passed into your templates.
# name: value

## Overrides for generated resource names
# See templates/_helpers.tpl
# nameOverride:
# fullnameOverride:
# namespaceOverride:

# For FQDN resolving of the master service. Change this value to match your existing configuration.
# ref: https://github.com/kubernetes/dns/blob/master/docs/specification.md
clusterZone: "cluster.local"

master:
  # Used for label app.kubernetes.io/component
  componentName: "jenkins-master"
  image: "jenkins/jenkins"
  tag: "lts"
  imagePullPolicy: "IfNotPresent"
  imagePullSecretName:
  # Optionally configure lifetime for master-container
  lifecycle:
  #  postStart:
  #    exec:
  #      command:
  #      - "uname"
  #      - "-a"
  numExecutors: 0
  customJenkinsLabels: []
  # configAutoReload requires UseSecurity is set to true:
  useSecurity: true

  # enables configuration done directly via XML files
  # People who want to configure Jenkins via https://github.com/jenkinsci/configuration-as-code-plugin only can set it to false
  enableXmlConfig: true
  # Allows to configure different SecurityRealm using Jenkins XML
  securityRealm: |-
    <securityRealm class="hudson.security.LegacySecurityRealm"/>
  # Allows to configure different AuthorizationStrategy using Jenkins XML
  authorizationStrategy: |-
     <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
       <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
     </authorizationStrategy>
  hostNetworking: false
  # When enabling LDAP or another non-Jenkins identity source, the built-in admin account will no longer exist.
  # Since the AdminUser is used by configAutoReload, in order to use configAutoReload you must change the
  # .master.adminUser to a valid username on your LDAP (or other) server.  This user does not need
  # to have administrator rights in Jenkins (the default Overall:Read is sufficient) nor will it be granted any
  # additional rights.  Failure to do this will cause the sidecar container to fail to authenticate via SSH and enter
  # a restart loop.  Likewise if you disable the non-Jenkins identity store and instead use the Jenkins internal one,
  # you should revert master.adminUser to your preferred admin user:
  adminUser: "admin"
  # adminPassword: <defaults to random>
  adminPassword: caffe
  # adminSshKey: <defaults to auto-generated>
  # If CasC auto-reload is enabled, an SSH (RSA) keypair is needed.  Can either provide your own, or leave unconfigured to allow a random key to be auto-generated.
  # If you supply your own, it is recommended that the values file that contains your key not be committed to source control in an unencrypted format
  rollingUpdate: {}
  # Ignored if Persistence is enabled
  # maxSurge: 1
  # maxUnavailable: 25%
  resources:
    requests:
      cpu: "50m"
      memory: "256Mi"
    limits:
      cpu: "2000m"
      memory: "4096Mi"
  # Environment variables that get added to the init container (useful for e.g. http_proxy)
  # initContainerEnv:
  #   - name: http_proxy
  #     value: "http://192.168.64.1:3128"
  # containerEnv:
  #   - name: http_proxy
  #     value: "http://192.168.64.1:3128"
  # Set min/max heap here if needed with:
  # javaOpts: "-Xms512m -Xmx512m"
  # jenkinsOpts: ""
  # jenkinsUrl: ""
  # If you set this prefix and use ingress controller then you might want to set the ingress path below
  # jenkinsUriPrefix: "/jenkins"
  # Enable pod security context (must be `true` if runAsUser or fsGroup are set)
  usePodSecurityContext: true
  # Set runAsUser to 1000 to let Jenkins run as non-root user 'jenkins' which exists in 'jenkins/jenkins' docker image.
  # When setting runAsUser to a different value than 0 also set fsGroup to the same value:
  # runAsUser: <defaults to 0>
  # fsGroup: <will be omitted in deployment if runAsUser is 0>
  servicePort: 8080
  targetPort: 8080
  # For minikube, set this to NodePort, elsewhere use LoadBalancer
  # Use ClusterIP if your setup includes ingress controller
  serviceType: ClusterIP
  # Jenkins master service annotations
  serviceAnnotations: {}
  # Jenkins master custom labels
  deploymentLabels: {}
  #   foo: bar
  #   bar: foo
  # Jenkins master service labels
  serviceLabels: {}
  #   service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https
  # Put labels on Jenkins master pod
  podLabels: {}
  # Used to create Ingress record (should used with ServiceType: ClusterIP)
  # nodePort: <to set explicitly, choose port between 30000-32767
  # Enable Kubernetes Liveness and Readiness Probes
  # ~ 2 minutes to allow Jenkins to restart when upgrading plugins. Set ReadinessTimeout to be shorter than LivenessTimeout.
  healthProbes: true
  healthProbesLivenessTimeout: 5
  healthProbesReadinessTimeout: 5
  healthProbeLivenessPeriodSeconds: 10
  healthProbeReadinessPeriodSeconds: 10
  healthProbeLivenessFailureThreshold: 5
  healthProbeReadinessFailureThreshold: 3
  healthProbeLivenessInitialDelay: 90
  healthProbeReadinessInitialDelay: 60
  slaveListenerPort: 50000
  slaveHostPort:
  disabledAgentProtocols:
    - JNLP-connect
    - JNLP2-connect
  csrf:
    defaultCrumbIssuer:
      enabled: true
      proxyCompatability: true
  cli: false
  # Kubernetes service type for the JNLP agent service
  # slaveListenerServiceType is the Kubernetes Service type for the JNLP agent service,
  # either 'LoadBalancer', 'NodePort', or 'ClusterIP'
  # Note if you set this to 'LoadBalancer', you *must* define annotations to secure it. By default
  # this will be an external load balancer and allowing inbound 0.0.0.0/0, a HUGE
  # security risk:  https://github.com/kubernetes/charts/issues/1341
  slaveListenerServiceType: "ClusterIP"
  slaveListenerServiceAnnotations: {}
  slaveKubernetesNamespace:

  # Example of 'LoadBalancer' type of agent listener with annotations securing it
  # slaveListenerServiceType: LoadBalancer
  # slaveListenerServiceAnnotations:
  #   service.beta.kubernetes.io/aws-load-balancer-internal: "True"
  #   service.beta.kubernetes.io/load-balancer-source-ranges: "172.0.0.0/8, 10.0.0.0/8"

  # LoadBalancerSourcesRange is a list of allowed CIDR values, which are combined with ServicePort to
  # set allowed inbound rules on the security group assigned to the master load balancer
  loadBalancerSourceRanges:
  - 0.0.0.0/0
  # Optionally assign a known public LB IP
  # loadBalancerIP: 1.2.3.4
  # Optionally configure a JMX port
  # requires additional javaOpts, ie
  # javaOpts: >
  #   -Dcom.sun.management.jmxremote.port=4000
  #   -Dcom.sun.management.jmxremote.authenticate=false
  #   -Dcom.sun.management.jmxremote.ssl=false
  # jmxPort: 4000
  # Optionally configure other ports to expose in the master container
  extraPorts: []
  # - name: BuildInfoProxy
  #   port: 9000

  # List of plugins to be install during Jenkins master start
  installPlugins:
    - kubernetes:1.18.2
    - workflow-job:2.33
    - workflow-aggregator:2.6
    - credentials-binding:1.19
    - git:3.11.0

  # Enable to always override the installed plugins with the values of 'master.installPlugins' on upgrade or redeployment.
  # overwritePlugins: true
  # Enable HTML parsing using OWASP Markup Formatter Plugin (antisamy-markup-formatter), useful with ghprb plugin.
  # The plugin is not installed by default, please update master.installPlugins.
  enableRawHtmlMarkupFormatter: false
  # Used to approve a list of groovy functions in pipelines used the script-security plugin. Can be viewed under /scriptApproval
  scriptApproval: []
  #  - "method groovy.json.JsonSlurperClassic parseText java.lang.String"
  #  - "new groovy.json.JsonSlurperClassic"
  # List of groovy init scripts to be executed during Jenkins master start
  initScripts: []
  #  - |
  #    print 'adding global pipeline libraries, register properties, bootstrap jobs...'
  # Kubernetes secret that contains a 'credentials.xml' for Jenkins
  # credentialsXmlSecret: jenkins-credentials
  # Kubernetes secret that contains files to be put in the Jenkins 'secrets' directory,
  # useful to manage encryption keys used for credentials.xml for instance (such as
  # master.key and hudson.util.Secret)
  # secretsFilesSecret: jenkins-secrets
  # Jenkins XML job configs to provision
  jobs: {}
  #  test: |-
  #    <<xml here>>

  # Below is the implementation of Jenkins Configuration as Code.  Add a key under configScripts for each configuration area,
  # where each corresponds to a plugin or section of the UI.  Each key (prior to | character) is just a label, and can be any value.
  # Keys are only used to give the section a meaningful name.  The only restriction is they may only contain RFC 1123 \ DNS label
  # characters: lowercase letters, numbers, and hyphens.  The keys become the name of a configuration yaml file on the master in
  # /var/jenkins_home/casc_configs (by default) and will be processed by the Configuration as Code Plugin.  The lines after each |
  # become the content of the configuration yaml file.  The first line after this is a JCasC root element, eg jenkins, credentials,
  # etc.  Best reference is https://<jenkins_url>/configuration-as-code/reference.  The example below creates a welcome message:
  JCasC:
    enabled: false
    defaultConfig: false
    pluginVersion: "1.27"
    # it's only used when plugin version is <=1.18 for later version the
    # configuration as code support plugin is no longer needed
    supportPluginVersion: "1.18"
    configScripts: {}
    # welcome-message: |
    #   jenkins:
    #     systemMessage: Welcome to our CI\CD server.  This Jenkins is configured and managed 'as code'.

  # Optionally specify additional init-containers
  customInitContainers: []
  # - name: custom-init
  #   image: "alpine:3.7"
  #   imagePullPolicy: Always
  #   command: [ "uname", "-a" ]

  sidecars:
    configAutoReload:
      # If enabled: true, Jenkins Configuration as Code will be reloaded on-the-fly without a reboot.  If false or not-specified,
      # jcasc changes will cause a reboot and will only be applied at the subsequent start-up.  Auto-reload uses the Jenkins CLI
      # over SSH to reapply config when changes to the configScripts are detected.  The admin user (or account you specify in
      # master.adminUser) will have a random SSH private key (RSA 4096) assigned unless you specify adminSshKey.  This will be saved to a k8s secret.
      enabled: false
      image: shadwell/k8s-sidecar:0.0.2
      imagePullPolicy: IfNotPresent
      resources: {}
        #   limits:
        #     cpu: 100m
        #     memory: 100Mi
        #   requests:
        #     cpu: 50m
        #     memory: 50Mi
      # SSH port value can be set to any unused TCP port.  The default, 1044, is a non-standard SSH port that has been chosen at random.
      # Is only used to reload jcasc config from the sidecar container running in the Jenkins master pod.
      # This TCP port will not be open in the pod (unless you specifically configure this), so Jenkins will not be
      # accessible via SSH from outside of the pod.  Note if you use non-root pod privileges (runAsUser & fsGroup),
      # this must be > 1024:
      sshTcpPort: 1044
      # folder in the pod that should hold the collected dashboards:
      folder: "/var/jenkins_home/casc_configs"
      # If specified, the sidecar will search for JCasC config-maps inside this namespace.
      # Otherwise the namespace in which the sidecar is running will be used.
      # It's also possible to specify ALL to search in all namespaces:
      # searchNamespace:

    # Allows you to inject additional/other sidecars
    other: []
    ## The example below runs the client for https://smee.io as sidecar container next to Jenkins,
    ## that allows to trigger build behind a secure firewall.
    ## https://jenkins.io/blog/2019/01/07/webhook-firewalls/#triggering-builds-with-webhooks-behind-a-secure-firewall
    ##
    ## Note: To use it you should go to https://smee.io/new and update the url to the generete one.
    # - name: smee
    #   image: docker.io/twalter/smee-client:1.0.2
    #   args: ["--port", "{{ .Values.master.servicePort }}", "--path", "/github-webhook/", "--url", "https://smee.io/new"]
    #   resources:
    #     limits:
    #       cpu: 50m
    #       memory: 128Mi
    #     requests:
    #       cpu: 10m
    #       memory: 32Mi
  # Node labels and tolerations for pod assignment
  # ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector
  # ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#taints-and-tolerations-beta-feature
  nodeSelector: {}
  tolerations: []
  # Leverage a priorityClass to ensure your pods survive resource shortages
  # ref: https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/
  # priorityClass: system-cluster-critical
  podAnnotations: {}

  # The below two configuration-related values are deprecated and replaced by Jenkins Configuration as Code (see above
  # JCasC key).  They will be deleted in an upcoming version.
  customConfigMap: false
  # By default, the configMap is only used to set the initial config the first time
  # that the chart is installed.  Setting `overwriteConfig` to `true` will overwrite
  # the jenkins config with the contents of the configMap every time the pod starts.
  # This will also overwrite all init scripts
  overwriteConfig: false

  # By default, the Jobs Map is only used to set the initial jobs the first time
  # that the chart is installed.  Setting `overwriteJobs` to `true` will overwrite
  # the jenkins jobs configuration with the contents of Jobs every time the pod starts.
  overwriteJobs: false

  ingress:
    enabled: false
    # For Kubernetes v1.14+, use 'networking.k8s.io/v1beta1'
    apiVersion: "extensions/v1beta1"
    labels: {}
    annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
    # Set this path to jenkinsUriPrefix above or use annotations to rewrite path
    # path: "/jenkins"
    # configures the hostname e.g. jenkins.example.com
    hostName:
    tls:
    # - secretName: jenkins.cluster.local
    #   hosts:
    #     - jenkins.cluster.local

  # If you're running on GKE and need to configure a backendconfig
  # to finish ingress setup, use the following values.
  # Docs: https://cloud.google.com/kubernetes-engine/docs/concepts/backendconfig
  backendconfig:
    enabled: false
    apiVersion: "extensions/v1beta1"
    name:
    labels: {}
    annotations: {}
    spec: {}

  # Openshift route
  route:
    enabled: false
    labels: {}
    annotations: {}
    # path: "/jenkins"

  additionalConfig: {}

  # master.hostAliases allows for adding entries to Pod /etc/hosts:
  # https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/
  hostAliases: []
  # - ip: 192.168.50.50
  #   hostnames:
  #     - something.local
  # - ip: 10.0.50.50
  #   hostnames:
  #     - other.local

  # Expose Prometheus metrics
  prometheus:
    # If enabled, add the prometheus plugin to the list of plugins to install
    # https://plugins.jenkins.io/prometheus
    enabled: false
    # Additional labels to add to the ServiceMonitor object
    serviceMonitorAdditionalLabels: {}
    # Set a custom namespace where to deploy ServiceMonitor resource
    # serviceMonitorNamespace: monitoring
    scrapeInterval: 60s
    # This is the default endpoint used by the prometheus plugin
    scrapeEndpoint: /prometheus
    # Additional labels to add to the PrometheusRule object
    alertingRulesAdditionalLabels: {}
    # An array of prometheus alerting rules
    # See here: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
    # The `groups` root object is added by default, simply add the rule entries
    alertingrules: []

  # Can be used to disable rendering master test resources when using helm template
  testEnabled: true

agent:
  enabled: true
  image: "jenkins/jnlp-slave"
  tag: "3.27-1"
  customJenkinsLabels: []
  # name of the secret to be used for image pulling
  imagePullSecretName:
  componentName: "jenkins-slave"
  privileged: false
  resources:
    requests:
      cpu: "512m"
      memory: "512Mi"
    limits:
      cpu: "512m"
      memory: "512Mi"
  # You may want to change this to true while testing a new image
  alwaysPullImage: false
  # Controls how agent pods are retained after the Jenkins build completes
  # Possible values: Always, Never, OnFailure
  podRetention: "Never"
  # You can define the volumes that you want to mount for this container
  # Allowed types are: ConfigMap, EmptyDir, HostPath, Nfs, Pod, Secret
  # Configure the attributes as they appear in the corresponding Java class for that type
  # https://github.com/jenkinsci/kubernetes-plugin/tree/master/src/main/java/org/csanchez/jenkins/plugins/kubernetes/volumes
  # Pod-wide ennvironment, these vars are visible to any container in the agent pod
  envVars: []
  # - name: PATH
  #   value: /usr/local/bin
  volumes: []
  # - type: Secret
  #   secretName: mysecret
  #   mountPath: /var/myapp/mysecret
  # - type: EmptyDir
  #   mountPath: "/var/lib/containers"
  #   memory: false
  nodeSelector: {}
  # Key Value selectors. Ex:
  # jenkins-agent: v1

  # Executed command when side container gets started
  command:
  args:
  # Side container name
  sideContainerName: "jnlp"
  # Doesn't allocate pseudo TTY by default
  TTYEnabled: false
  # Max number of spawned agent
  containerCap: 10
  # Pod name
  podName: "default"
  # Allows the Pod to remain active for reuse until the configured number of
  # minutes has passed since the last step was executed on it.
  idleMinutes: 0
  # Raw yaml template for the Pod. For example this allows usage of toleration for agent pods.
  # https://github.com/jenkinsci/kubernetes-plugin#using-yaml-to-define-pod-templates
  # https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
  yamlTemplate: ""
  # yamlTemplate: |-
  #   apiVersion: v1
  #   kind: Pod
  #   spec:
  #     tolerations:
  #     - key: "key"
  #       operator: "Equal"
  #       value: "value"

persistence:
  enabled: true
  ## A manually managed Persistent Volume and Claim
  ## Requires persistence.enabled: true
  ## If defined, PVC must be created manually before volume will be bound
  existingClaim:
  ## jenkins data Persistent Volume Storage Class
  ## If defined, storageClassName: <storageClass>
  ## If set to "-", storageClassName: "", which disables dynamic provisioning
  ## If undefined (the default) or set to null, no storageClassName spec is
  ##   set, choosing the default provisioner.  (gp2 on AWS, standard on
  ##   GKE, AWS & OpenStack)
  ##
  storageClass: hostpath
  annotations: {}
  accessMode: "ReadWriteOnce"
  size: "8Gi"
  volumes:
  #  - name: nothing
  #    emptyDir: {}
  mounts:
  #  - mountPath: /var/nothing
  #    name: nothing
  #    readOnly: true

networkPolicy:
  # Enable creation of NetworkPolicy resources.
  enabled: false
  # For Kubernetes v1.4, v1.5 and v1.6, use 'extensions/v1beta1'
  # For Kubernetes v1.7, use 'networking.k8s.io/v1'
  apiVersion: networking.k8s.io/v1

## Install Default RBAC roles and bindings
rbac:
  create: true

serviceAccount:
  create: true
  # The name of the service account is autogenerated by default
  name:
  annotations: {}

serviceAccountAgent:
  # Specifies whether a ServiceAccount should be created
  create: false
  # The name of the ServiceAccount to use.
  # If not set and create is true, a name is generated using the fullname template
  name:
  annotations: {}
checkDeprecation: true
```

jenkins-ingress.yaml

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubernetes-jenkins-ingress
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: kubernetes-jenkins.domain.com
    http:
      paths:
      - backend:
          serviceName: kubernetes-jenkins
          servicePort: 8080
        path: /
```

## 10 安装Harbor

```shell
helm install --namespace kube-system --name kubernetes-harbor -f values.yaml . 
```

values.yaml

```yaml
expose:
  # Set the way how to expose the service. Set the type as "ingress",
  # "clusterIP", "nodePort" or "loadBalancer" and fill the information
  # in the corresponding section
  type: ingress
  tls:
    # Enable the tls or not. Note: if the type is "ingress" and the tls
    # is disabled, the port must be included in the command when pull/push
    # images. Refer to https://github.com/goharbor/harbor/issues/5291
    # for the detail.
    enabled: true
    # Fill the name of secret if you want to use your own TLS certificate.
    # The secret contains keys named:
    # "tls.crt" - the certificate (required)
    # "tls.key" - the private key (required)
    # "ca.crt" - the certificate of CA (optional), this enables the download
    # link on portal to download the certificate of CA
    # These files will be generated automatically if the "secretName" is not set
    secretName: ""
    # By default, the Notary service will use the same cert and key as
    # described above. Fill the name of secret if you want to use a
    # separated one. Only needed when the type is "ingress".
    notarySecretName: ""
    # The common name used to generate the certificate, it's necessary
    # when the type isn't "ingress" and "secretName" is null
    commonName: ""
  ingress:
    hosts:
      core: kubernetes-harbor.domain.com
      notary: notary.harbor.domain
    # set to the type of ingress controller if it has specific requirements.
    # leave as `default` for most ingress controllers.
    # set to `gce` if using the GCE ingress controller
    # set to `ncp` if using the NCP (NSX-T Container Plugin) ingress controller
    controller: default
    annotations:
      kubernetes.io/ingress.class: "nginx"
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
  clusterIP:
    # The name of ClusterIP service
    name: harbor
    ports:
      # The service port Harbor listens on when serving with HTTP
      httpPort: 80
      # The service port Harbor listens on when serving with HTTPS
      httpsPort: 443
      # The service port Notary listens on. Only needed when notary.enabled
      # is set to true
      notaryPort: 4443
  nodePort:
    # The name of NodePort service
    name: harbor
    ports:
      http:
        # The service port Harbor listens on when serving with HTTP
        port: 80
        # The node port Harbor listens on when serving with HTTP
        nodePort: 30002
      https:
        # The service port Harbor listens on when serving with HTTPS
        port: 443
        # The node port Harbor listens on when serving with HTTPS
        nodePort: 30003
      # Only needed when notary.enabled is set to true
      notary:
        # The service port Notary listens on
        port: 4443
        # The node port Notary listens on
        nodePort: 30004
  loadBalancer:
    # The name of LoadBalancer service
    name: harbor
    # Set the IP if the LoadBalancer supports assigning IP
    IP: ""
    ports:
      # The service port Harbor listens on when serving with HTTP
      httpPort: 80
      # The service port Harbor listens on when serving with HTTPS
      httpsPort: 443
      # The service port Notary listens on. Only needed when notary.enabled
      # is set to true
      notaryPort: 4443
    annotations: {}
    sourceRanges: []

# The external URL for Harbor core service. It is used to
# 1) populate the docker/helm commands showed on portal
# 2) populate the token service URL returned to docker/notary client
#
# Format: protocol://domain[:port]. Usually:
# 1) if "expose.type" is "ingress", the "domain" should be
# the value of "expose.ingress.hosts.core"
# 2) if "expose.type" is "clusterIP", the "domain" should be
# the value of "expose.clusterIP.name"
# 3) if "expose.type" is "nodePort", the "domain" should be
# the IP address of k8s node
#
# If Harbor is deployed behind the proxy, set it as the URL of proxy
externalURL: https://kubernetes-harbor.domain.com

# The persistence is enabled by default and a default StorageClass
# is needed in the k8s cluster to provision volumes dynamicly.
# Specify another StorageClass in the "storageClass" or set "existingClaim"
# if you have already existing persistent volumes to use
#
# For storing images and charts, you can also use "azure", "gcs", "s3",
# "swift" or "oss". Set it in the "imageChartStorage" section
persistence:
  enabled: true
  # Setting it to "keep" to avoid removing PVCs during a helm delete
  # operation. Leaving it empty will delete PVCs after the chart deleted
  # resourcePolicy: "keep"
  resourcePolicy: ""
  persistentVolumeClaim:
    registry:
      # Use the existing PVC which must be created manually before bound,
      # and specify the "subPath" if the PVC is shared with other components
      existingClaim: ""
      # Specify the "storageClass" used to provision the volume. Or the default
      # StorageClass will be used(the default).
      # Set it to "-" to disable dynamic provisioning
      storageClass: "hostpath"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 5Gi
    chartmuseum:
      existingClaim: ""
      storageClass: "hostpath"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 5Gi
    jobservice:
      existingClaim: ""
      storageClass: "hostpath"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
    # If external database is used, the following settings for database will
    # be ignored
    database:
      existingClaim: ""
      storageClass: "hostpath"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
    # If external Redis is used, the following settings for Redis will
    # be ignored
    redis:
      existingClaim: ""
      storageClass: "hostpath"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 1Gi
  # Define which storage backend is used for registry and chartmuseum to store
  # images and charts. Refer to
  # https://github.com/docker/distribution/blob/master/docs/configuration.md#storage
  # for the detail.
  imageChartStorage:
    # Specify whether to disable `redirect` for images and chart storage, for
    # backends which not supported it (such as using minio for `s3` storage type), please disable
    # it. To disable redirects, simply set `disableredirect` to `true` instead.
    # Refer to
    # https://github.com/docker/distribution/blob/master/docs/configuration.md#redirect
    # for the detail.
    disableredirect: false
    # Specify the "caBundleSecretName" if the storage service uses a self-signed certificate.
    # The secret must contain keys named "ca.crt" which will be injected into the trust store
    # of registry's and chartmuseum's containers.
    # caBundleSecretName:

    # Specify the type of storage: "filesystem", "azure", "gcs", "s3", "swift",
    # "oss" and fill the information needed in the corresponding section. The type
    # must be "filesystem" if you want to use persistent volumes for registry
    # and chartmuseum
    type: filesystem
    filesystem:
      rootdirectory: /storage
      #maxthreads: 100
    azure:
      accountname: accountname
      accountkey: base64encodedaccountkey
      container: containername
      #realm: core.windows.net
    gcs:
      bucket: bucketname
      # The base64 encoded json file which contains the key
      encodedkey: base64-encoded-json-key-file
      #rootdirectory: /gcs/object/name/prefix
      #chunksize: "5242880"
    s3:
      region: us-west-1
      bucket: bucketname
      #accesskey: awsaccesskey
      #secretkey: awssecretkey
      #regionendpoint: http://myobjects.local
      #encrypt: false
      #keyid: mykeyid
      #secure: true
      #v4auth: true
      #chunksize: "5242880"
      #rootdirectory: /s3/object/name/prefix
      #storageclass: STANDARD
    swift:
      authurl: https://storage.myprovider.com/v3/auth
      username: username
      password: password
      container: containername
      #region: fr
      #tenant: tenantname
      #tenantid: tenantid
      #domain: domainname
      #domainid: domainid
      #trustid: trustid
      #insecureskipverify: false
      #chunksize: 5M
      #prefix:
      #secretkey: secretkey
      #accesskey: accesskey
      #authversion: 3
      #endpointtype: public
      #tempurlcontainerkey: false
      #tempurlmethods:
    oss:
      accesskeyid: accesskeyid
      accesskeysecret: accesskeysecret
      region: regionname
      bucket: bucketname
      #endpoint: endpoint
      #internal: false
      #encrypt: false
      #secure: true
      #chunksize: 10M
      #rootdirectory: rootdirectory

imagePullPolicy: IfNotPresent

# Use this set to assign a list of default pullSecrets
imagePullSecrets:
#  - name: docker-registry-secret
#  - name: internal-registry-secret

logLevel: debug
# The initial password of Harbor admin. Change it from portal after launching Harbor
harborAdminPassword: "Harbor12345"
# The secret key used for encryption. Must be a string of 16 chars.
secretKey: "not-a-secure-key"

# The proxy settings for updating clair vulnerabilities from the Internet and replicating
# artifacts from/to the registries that cannot be reached directly
proxy:
  httpProxy:
  httpsProxy:
  noProxy: 127.0.0.1,localhost,.local,.internal
  components:
    - core
    - jobservice
    - clair

## UAA Authentication Options
# If you're using UAA for authentication behind a self-signed
# certificate you will need to provide the CA Cert.
# Set uaaSecretName below to provide a pre-created secret that
# contains a base64 encoded CA Certificate named `ca.crt`.
# uaaSecretName:

# If expose the service via "ingress", the Nginx will not be used
nginx:
  image:
    repository: goharbor/nginx-photon
    tag: dev
  replicas: 1
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

portal:
  image:
    repository: goharbor/harbor-portal
    tag: dev
  replicas: 1
# resources:
#  requests:
#    memory: 256Mi
#    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

core:
  image:
    repository: goharbor/harbor-core
    tag: dev
  replicas: 1
  ## Liveness probe values
  livenessProbe:
    initialDelaySeconds: 300
# resources:
#  requests:
#    memory: 256Mi
#    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}
  # Secret is used when core server communicates with other components.
  # If a secret key is not specified, Helm will generate one.
  # Must be a string of 16 chars.
  secret: ""
  # Fill the name of a kubernetes secret if you want to use your own
  # TLS certificate and private key for token encryption/decryption.
  # The secret must contain keys named:
  # "tls.crt" - the certificate
  # "tls.key" - the private key
  # The default key pair will be used if it isn't set
  secretName: ""

jobservice:
  image:
    repository: goharbor/harbor-jobservice
    tag: dev
  replicas: 1
  maxJobWorkers: 10
  # The logger for jobs: "file", "database" or "stdout"
  jobLogger: file
# resources:
#   requests:
#     memory: 256Mi
#     cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}
  # Secret is used when job service communicates with other components.
  # If a secret key is not specified, Helm will generate one.
  # Must be a string of 16 chars.
  secret: ""

registry:
  registry:
    image:
      repository: goharbor/registry-photon
      tag: dev

    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
  controller:
    image:
      repository: goharbor/harbor-registryctl
      tag: dev

    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
  replicas: 1
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}
  # Secret is used to secure the upload state from client
  # and registry storage backend.
  # See: https://github.com/docker/distribution/blob/master/docs/configuration.md#http
  # If a secret key is not specified, Helm will generate one.
  # Must be a string of 16 chars.
  secret: ""
  # If true, the registry returns relative URLs in Location headers. The client is responsible for resolving the correct URL.
  relativeurls: false
  middleware:
    enabled: false
    type: cloudFront
    cloudFront:
      baseurl: example.cloudfront.net
      keypairid: KEYPAIRID
      duration: 3000s
      ipfilteredby: none
      # The secret key that should be present is CLOUDFRONT_KEY_DATA, which should be the encoded private key
      # that allows access to CloudFront
      privateKeySecret: "my-secret"

chartmuseum:
  enabled: true
  # Harbor defaults ChartMuseum to returning relative urls, if you want using absolute url you should enable it by change the following value to 'true'
  absoluteUrl: false
  image:
    repository: goharbor/chartmuseum-photon
    tag: dev
  replicas: 1
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

clair:
  enabled: true
  clair:
    image:
      repository: goharbor/clair-photon
      tag: dev
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
  adapter:
    image:
      repository: goharbor/clair-adapter-photon
      tag: dev
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
  replicas: 1
  # The interval of clair updaters, the unit is hour, set to 0 to
  # disable the updaters
  updatersInterval: 12
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

notary:
  enabled: true
  server:
    image:
      repository: goharbor/notary-server-photon
      tag: dev
    replicas: 1
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
  signer:
    image:
      repository: goharbor/notary-signer-photon
      tag: dev
    replicas: 1
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}
  # Fill the name of a kubernetes secret if you want to use your own
  # TLS certificate authority, certificate and private key for notary
  # communications.
  # The secret must contain keys named ca.crt, tls.crt and tls.key that
  # contain the CA, certificate and private key.
  # They will be generated if not set.
  secretName: ""

database:
  # if external database is used, set "type" to "external"
  # and fill the connection informations in "external" section
  type: internal
  internal:
    image:
      repository: goharbor/harbor-db
      tag: dev
    # The initial superuser password for internal database
    password: "changeit"
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    nodeSelector: {}
    tolerations: []
    affinity: {}
  external:
    host: "192.168.0.1"
    port: "5432"
    username: "user"
    password: "password"
    coreDatabase: "registry"
    clairDatabase: "clair"
    notaryServerDatabase: "notary_server"
    notarySignerDatabase: "notary_signer"
    # "disable" - No SSL
    # "require" - Always SSL (skip verification)
    # "verify-ca" - Always SSL (verify that the certificate presented by the
    # server was signed by a trusted CA)
    # "verify-full" - Always SSL (verify that the certification presented by the
    # server was signed by a trusted CA and the server host name matches the one
    # in the certificate)
    sslmode: "disable"
  # The maximum number of connections in the idle connection pool.
  # If it <=0, no idle connections are retained.
  maxIdleConns: 50
  # The maximum number of open connections to the database.
  # If it <= 0, then there is no limit on the number of open connections.
  # Note: the default number of connections is 100 for postgre.
  maxOpenConns: 100
  ## Additional deployment annotations
  podAnnotations: {}

redis:
  # if external Redis is used, set "type" to "external"
  # and fill the connection informations in "external" section
  type: internal
  internal:
    image:
      repository: goharbor/redis-photon
      tag: dev
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    nodeSelector: {}
    tolerations: []
    affinity: {}
  external:
    host: "192.168.0.2"
    port: "6379"
    # The "coreDatabaseIndex" must be "0" as the library Harbor
    # used doesn't support configuring it
    coreDatabaseIndex: "0"
    jobserviceDatabaseIndex: "1"
    registryDatabaseIndex: "2"
    chartmuseumDatabaseIndex: "3"
    password: ""
  ## Additional deployment annotations
  podAnnotations: {}
```

## 11 生成tls

generate_ca.sh

```shell
 #!/bin/sh

# create self-signed server certificate:
read -p "Enter your domain [www.example.com]: " DOMAIN
echo "Create server key..."
openssl genrsa -des3 -out $DOMAIN.key 1024

echo "Create server certificate signing request..."
SUBJECT="/C=US/ST=Mars/L=iTranswarp/O=iTranswarp/OU=iTranswarp/CN=$DOMAIN"
openssl req -new -subj $SUBJECT -key $DOMAIN.key -out $DOMAIN.csr

echo "Remove password..."
mv $DOMAIN.key $DOMAIN.origin.key
openssl rsa -in $DOMAIN.origin.key -out $DOMAIN.key

echo "Sign SSL certificate..."
openssl x509 -req -days 3650 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt

echo "Done!"
```

创建secret

```shell
kubectl create secret tls kubernetes-jenkins-tls --key kubernetes-jenkins.domain.com.key --cert kubernetes-jenkins.domain.com.crt -n kube-system
```

## 12 helm仓库

```shell
[root@laptop harbor-helm]# helm repo list
NAME            URL
local           http://127.0.0.1:8879/charts
aliyun          https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
stable          http://mirror.azure.cn/kubernetes/charts/
incubator       http://mirror.azure.cn/kubernetes/charts-incubator/
rimusz          https://charts.rimusz.net
gitlab          https://charts.gitlab.io/
```

## 13 harbor的仓库

```shell
https://github.com/goharbor/harbor-helm/blob/master/values.yaml
```

## 14 Jenkins的配置

```groovy
def label = "mypod-${UUID.randomUUID().toString()}"
podTemplate(label: label, cloud: 'kubernetes') {
    node(label) {
        stage('Run shell') {
            sh 'sleep 130s'
            sh 'echo hello world.'
        }
    }
}
```

```html
https://blog.csdn.net/aixiaoyang168/article/details/79767649
```

```groovy
pipeline {
    agent { label 'kubernetes-jenkins-jenkins-slave-cpp' }
    stages {
        stage('Checkout') {
            steps {
                echo 'Checkout'
                checkout(
                    [
                        $class: 'GitSCM', 
                        branches: [[name: '*/master']], 
                        doGenerateSubmoduleConfigurations: false, extensions: [], 
                        submoduleCfg: [], 
                        userRemoteConfigs: [[
                            credentialsId: 'ef87c62b-9eff-45e8-bb7a-1c5a4ccaa976', 
                            url: 'http://kubernetes-gitlab-gitlab-ce/juno/hello_jenkins'
                        ]]
                    ]
                )
            }
        }        
        stage('Build') {
            steps {
                echo "Building ${env.BUILD_ID} on ${env.JENKINS_URL}"
                sh 'make'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing'
                sh './hello_exec'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying'
            }
        }
    }
}
```

## 15 CI/CD

```shell
# build.sh
#!/bin/bash

MODULE=$1
TIME=`date "+%Y%m%d%H%M"`
GIT_REVISION=`git log -1 --pretty=format:"%h"`
IMAGE_NAME=hub.nnkwrik.com/micro-service/${MODULE}:${TIME}_${GIT_REVISION}
cd ${MODULE}

docker build -t ${IMAGE_NAME} .
cd -

docker push ${IMAGE_NAME}

echo "${IMAGE_NAME}" > IMAGE_NAME
```

```shell
# deploy.sh
#!/bin/bash

IMAGE=`cat IMAGE_NAME`
DEPLOYMENT=$1
MODULE=$2
PATH=$PATH:/root/bin
export PATH
echo "update image to:${IMAGE}"
kubectl set image deployments/${DEPLOYMENT} ${MODULE}=${IMAGE}
```

```groovy
# jenkins.groovy
#!/groovy
pipeline{
	agent any

	environment {
		REPOSITORY="ssh://git@gitlab.nnkwrik.com:2222/nnkwrik/microservice.git"
		MODULE="user-edge-service"
		SCRIPT_PATH="/home/ubuntu/scripts"
	}

	stages {
		stage('获取代码') {
			steps {
				echo "start fetch code from git:${REPOSITORY}"
				deleteDir()
				git "${REPOSITORY}"
			}
		}

		stage('代码静态检查') {
			steps {
				echo "start code check"
			}
		}

		stage('编译+单元测试') {
			steps {
				echo "star compile"
				sh "mvn -U -pl ${MODULE} -am clean package"
			}
		}

		stage('构建镜像') {
			steps {
				echo "start build image"
				sh "${SCRIPT_PATH}/build-images.sh ${MODULE}"
			}
		}

		stage('发布系统') {
			steps {
				echo "start deploy"
				sh "${SCRIPT_PATH}/deploy.sh user-service-deployment ${MODULE}"
			}
		}
	}
}
```

