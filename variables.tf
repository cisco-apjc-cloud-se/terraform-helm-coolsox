# variable "namespace" {
#   type = string
#   default = "coolsox"
#   nullable = false
# }

variable "smm_enabled" {
  type = bool
  default = false
  nullable = false
}

variable "panoptica_enabled" {
  type = bool
  default = false
  nullable = false
}

### Helm Variables ###
variable "helm" {
  type = object({
    release_name = string
    namespace    = string
    repository   = string
    chart        = string
    version      = string
    wait         = bool
    })
}

### Application Variables ###
variable "settings" {
  type = object({
    kubernetes = object({
      repository                = string
      image_pull_policy         = optional(string)
      read_only_root_filesystem = optional(bool)
      })
    carts = object({
      version       = optional(string)
      replicas      = optional(number)
      })
    catalogue_db = object({
      version       = optional(string)
      # replicas      = optional(number)
      })
    catalogue = object({
      version       = optional(string)
      replicas      = optional(number)
      appd_tiername = optional(string)
      })
    frontend = object({
      version                   = optional(string)
      replicas                  = optional(number)
      appd_browser_rum_enabled  = optional(bool)
      # # RUM Variables - note that / characters must be escaped using \/
      # AppD_appKey: <app_key>
      # AppD_adrumExtUrlHttp: http:\/\/cdn.appdynamics.com
      # AppD_adrumExtUrlHttps: https:\/\/cdn.appdynamics.com
      # AppD_beaconUrlHttp: http:\/\/fra-col.eum-appdynamics.com
      # AppD_beaconUrlHttps: https:\/\/fra-col.eum-appdynamics.com
      # AppD_adrumLocation: cdn.appdynamics.com\/adrum\/adrum-21.4.0.3405.js
      ingress = object({
        enabled = optional(bool)
        url = optional(string)
        })
      loadbalancer = object({
        enabled = optional(bool)
        })
      })
    orders = object({
      version       = optional(string)
      replicas      = optional(number)
      })
    payment = object({
      version       = optional(string)
      replicas      = optional(number)
      appd_tiername = optional(string)
      })
    queue = object({
      version       = optional(string)
      # replicas      = optional(number)
      })
    shipping = object({
      version       = optional(string)
      replicas      = optional(number)
      })
    user_db = object({
      version       = optional(string)
      # replicas      = optional(number)
      })
    user = object({
      version       = optional(string)
      replicas      = optional(number)
      appd_tiername = optional(string)
      })
    load_test = object({
      enabled       = bool
      version       = optional(string)
      replicas      = optional(number)
      })
    })
}

## AppD Variables ##
variable "appd" {
  type = object({
    application = object({
      name = string
      })
    account = object({
      host           = string
      port           = optional(number)
      use_ssl        = optional(bool)
      name           = string
      key            = string
      otel_api_key   = optional(string)
      username       = optional(string)
      password       = optional(string)
      # global_account = optional(string)
    })
    db_agent = object({
      enabled     = bool
      name        = optional(string)
      version     = optional(string)
      properties  = optional(string)
      databases   = optional(map(object({
        name      = string
        user      = string
        password  = string
        })))
      })
  })
}
