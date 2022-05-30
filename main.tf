terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  experiments = [module_variable_optional_attrs]
}

locals {
  appd = defaults(var.appd, {
    account = {
      # host = format("%s.saas.appdynamics.com", var.appd.account.name)
      port = 443
      use_ssl = true
    }
    db_agent = {
      enabled = false
      name    = "appd-db-agent"
      version = "latest" #"21.9.0.2521" # latest?
      properties = "-Ddbagent.telemetry.enabled=true"
      databases = {}
    }
  })

  settings = defaults(var.settings, {
    kubernetes = {
      image_pull_policy         = "Always"
      read_only_root_filesystem = true
    }
    carts = {
      version = "latest"
      replicas = 1
    }
    catalogue_db = {
      version = "latest"
    }
    catalogue = {
      version = "latest"
      replicas = 1
      appd_tiername = "catalogue"
    }
    frontend = {
      version = "latest"
      replicas = 1
      appd_browser_rum_enabled = false
      # # RUM Variables - note that / characters must be escaped using \/
      # AppD_appKey: <app_key>
      # AppD_adrumExtUrlHttp: http:\/\/cdn.appdynamics.com
      # AppD_adrumExtUrlHttps: https:\/\/cdn.appdynamics.com
      # AppD_beaconUrlHttp: http:\/\/fra-col.eum-appdynamics.com
      # AppD_beaconUrlHttps: https:\/\/fra-col.eum-appdynamics.com
      # AppD_adrumLocation: cdn.appdynamics.com\/adrum\/adrum-21.4.0.3405.js
    }
    orders = {
      version = "latest"
      replicas = 1
    }
    payment = {
      version = "latest"
      replicas = 1
      appd_tiername = "payment"
    }
    queue = {
      version = "latest"
    }
    shipping = {
      version = "latest"
      replicas = 1
    }
    user_db = {
      version = "latest"
    }
    user = {
      version = "latest"
      replicas = 1
      appd_tiername = "user"
    }
    load_test = {
      version = "latest"
      replicas = 1
      enabled = false
    }
  })
}

### Kubernetes  ###

resource "kubernetes_namespace" "coolsox" {
  metadata {
    annotations = {
      name = var.helm.namespace
    }
    labels = {
      "app.kubernetes.io/name" = var.helm.namespace

      ## SMM Sidecard Proxy Auto Injection ##
      "istio.io/rev" = var.smm_enabled == true ? "cp-v111x.istio-system" : ""

      ## SecureCN
      "SecureApplication-protected" = var.panoptica_enabled == true ? "full" : ""
    }
    name = var.helm.namespace
  }
}

### Helm ###

resource "helm_release" "coolsox" {

  name        = var.helm.release_name
  namespace   = kubernetes_namespace.coolsox.metadata[0].name
  repository  = var.helm.repository
  chart       = var.helm.chart
  version     = var.helm.version
  wait        = var.helm.wait
  timeout     = var.helm.timeout

  values = [<<EOF

appd:
    APPD_APPNAME: "${local.appd.application.name}"
    APPD_CONTROLLER_HOST: "${local.appd.account.host}"
    APPD_CONTROLLER_PORT: "${local.appd.account.port}"
    APPD_CONTROLLER_USE_SSL: "${local.appd.account.use_ssl}"
    APPD_CONTROLLER_ACCOUNT: "${local.appd.account.name}"
    APPD_CONTROLLER_ACCESS_KEY: "${local.appd.account.key}"

kubernetes:
    repository: ${local.settings.kubernetes.repository}
    imagePullPolicy: ${local.settings.kubernetes.image_pull_policy}
    readOnlyRootFilesystem: ${local.settings.kubernetes.read_only_root_filesystem}
java:
    options: -Xms64m -Xmx128m -XX:PermSize=32m -XX:MaxPermSize=64m -XX:+UseG1GC -Djava.security.egd=file:/dev/urandom

# Carts settings
carts:
    version: ${local.settings.carts.version}
    replicas: ${local.settings.carts.replicas}
# Catalogue-db settings
catalogue_db:
    version: ${local.settings.catalogue_db.version}
# Catalogue settings
catalogue:
    APPD_TIERNAME: ${local.settings.catalogue.appd_tiername}
    version: ${local.settings.catalogue.version}
# Front-end settings
frontend:
    version: ${local.settings.frontend.version}
    replicas: ${local.settings.frontend.replicas}
    appd_browser_rum_enabled: ${local.settings.frontend.appd_browser_rum_enabled}
    # RUM Variables - note that / characters must be escaped using \/
    AppD_appKey: ${local.appd.account.key}
    # AppD_adrumExtUrlHttp: http:\/\/cdn.appdynamics.com
    # AppD_adrumExtUrlHttps: https:\/\/cdn.appdynamics.com
    # AppD_beaconUrlHttp: http:\/\/fra-col.eum-appdynamics.com
    # AppD_beaconUrlHttps: https:\/\/fra-col.eum-appdynamics.com
    # AppD_adrumLocation: cdn.appdynamics.com\/adrum\/adrum-21.4.0.3405.js

    # Controls the deployment of kubernets ingress controller for front-end
    ingress:
        enabled: ${local.settings.frontend.ingress.enabled}
        url: ${local.settings.frontend.ingress.url}

    # Controls the deployment of kubernetes loadbalancer for front-end
    loadbalancer:
        enabled: ${local.settings.frontend.loadbalancer.enabled}

# Orders settings
orders:
    version: ${local.settings.orders.version}
    replicas: ${local.settings.orders.replicas}
# Payment settings
payment:
    APPD_TIERNAME: ${local.settings.payment.appd_tiername}
    version: ${local.settings.payment.version}
    replicas: ${local.settings.payment.replicas}
# Queue-master settings
queue_master:
    version: ${local.settings.queue.version}
# Shipping settings
shipping:
    version: ${local.settings.shipping.version}
# User-db settings
user_db:
    version: ${local.settings.user_db.version}
# User settings
user:
    APPD_TIERNAME: ${local.settings.user.appd_tiername}
    version: ${local.settings.user.version}
    replicas: ${local.settings.user.replicas}

# Controls the deployment of build-in load-test
loadtest:
    version: ${local.settings.load_test.version}
    replicas: ${local.settings.load_test.replicas}
    enabled: ${local.settings.load_test.enabled}

# Controls the deployment of AppDynamics DB Agent
appdynamics_db_agent:
    enabled: ${local.appd.db_agent.enabled}
    dbagent_name: ${local.appd.db_agent.name}
    dbagent_version: ${local.appd.db_agent.version}
    dbagent_properties: ${local.appd.db_agent.properties}
    mongodb_user: ${try(local.appd.db_agent.databases["mongodb"].user, "")}
    mongodb_password: ${try(local.appd.db_agent.databases["mongodb"].password, "")}

EOF
  ]
}
