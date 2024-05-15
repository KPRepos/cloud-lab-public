resource "kubernetes_namespace" "argocd" {
  count = var.enable_argocd_helm_release ? 1 : 0
  metadata {
    name = var.argocd_k8s_namespace
  }
}


resource "helm_release" "argocd" {
  count            = var.enable_argocd_helm_release ? 1 : 0
  name             = var.argocd_helm_release_name
  namespace        = var.argocd_k8s_namespace
  repository       = var.argocd_helm_repo
  chart            = var.argocd_helm_chart
  version          = var.argocd_helm_chart_version
  timeout          = var.argocd_helm_chart_timeout_seconds
  create_namespace = false
  set {
    name  = "installCRDs"
    value = true
  }

  set {
    name  = "crds.install"
    value = true
  }


  depends_on = [kubernetes_namespace.argocd]

  # Additional Helm values
  # Enable if you want to install high-availability argocd
  # values = [
  #   file(var.argocd_additional_helm_values_file)
  # ]
}

#https://github.com/hivenetes/k8s-bootstrapper/blob/main/infrastructure/terraform/argocd-helm-config.tf

# ===================== ARGOCD HELM CONFIG VARS =======================

variable "enable_argocd_helm_release" {
  type        = bool
  default     = true
  description = "Enable/disable ArgoCD Helm chart deployment on DOKS"
}

variable "argocd_helm_repo" {
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
  description = "ArgoCD Helm chart repository URL"
}

variable "argocd_helm_chart" {
  type        = string
  default     = "argo-cd"
  description = "argocd Helm chart name"
}

variable "argocd_helm_release_name" {
  type        = string
  default     = "argocd"
  description = "argocd Helm release name"
}

variable "argocd_helm_chart_version" {
  type        = string
  default     = "6.5.0"
  description = "ArgoCD Helm chart version to deploy"
}
variable "argocd_helm_chart_timeout_seconds" {
  type        = number
  default     = 300
  description = "Timeout value for Helm chart install/upgrade operations"
}

variable "argocd_k8s_namespace" {
  type        = string
  default     = "argocd"
  description = "Kubernetes namespace to use for the argocd Helm release"
}

variable "argocd_additional_helm_values_file" {
  type        = string
  default     = "argocd-ha-helm-values.yaml"
  description = "Additional Helm values to use"
}


variable "auto_deploy_sample_apps" {
  type        = string
  description = "Deploy-ArgoCD"
}



# ================================== ARGOCD ==================================

## 
resource "null_resource" "argocd_wait" {
  count      = var.enable_argocd_helm_release ? 1 : 0
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = "until kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.phase}' | grep Running; do echo 'waiting for argocd-server to be ready' && sleep 10; done"
  }
}

# ## 
# resource "null_resource" "argocd_crds_wait" {
#   count      = var.enable_argocd_helm_release ? 1 : 0
#   depends_on = [helm_release.argocd]

#   provisioner "local-exec" {
#     command = "until kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.phase}' | grep Running; do echo 'waiting for argocd-server to be ready' && sleep 10; done"
#   }
# }


# resource "kubernetes_manifest" "argo_cd_crds" {
#   count = var.enable_argocd_helm_release ? 1 : 0
#   manifest = {
#     apiVersion = "apiextensions.k8s.io/v1"
#     kind       = "CustomResourceDefinition"
#     metadata = {
#       name = "applications.argoproj.io"
#     }
#     spec = {
#       group = "argoproj.io"
#       versions = [
#         {
#           name    = "v1alpha1"
#           served  = true
#           storage = true
#         }
#       ]
#       scope = "Namespaced"
#       names = {
#         plural     = "applications"
#         singular   = "application"
#         kind       = "Application"
#         shortNames = ["app"]
#       }
#     }
#   }
#   depends_on = [helm_release.argocd]
# }



resource "kubernetes_manifest" "argo_app" {
  count = var.auto_deploy_sample_apps ? 1 : 0
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "nginx-sample-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/KPRepos/cloud-lab-public.git"
        targetRevision = "main"
        path           = "aws/eks/eks-sample-apps/argo-cd-apps"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }

      syncPolicy = {
        automated = {
          selfHeal = true
          prune    = true
        }
      }
    }
  }
  depends_on = [helm_release.argocd, null_resource.argocd_wait]
}

# , kubernetes_manifest.argo_cd_crds

output "argocd_helm_chart_values" {
  value = var.enable_argocd_helm_release ? helm_release.argocd[0].values : null
}

output "argocd_helm_chart_manifest" {
  value = var.enable_argocd_helm_release ? helm_release.argocd[0].manifest : null
}


## For UI

# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo


# kubectl port-forward -n argocd service/argocd-server 8443:443

