variable "project_name" {
  type = string
}

# Nombres EXACTOS usados en los scripts oficiales del docente
# (ecr-push.sh / deploy-containers.sh): "freshbox-frontend", etc.
# Se dejan como constante porque deben calzar 1:1 con esos scripts.
variable "repository_names" {
  type = list(string)
  default = [
    "freshbox-frontend",
    "freshbox-get-products",
    "freshbox-create-product",
    "freshbox-update-product",
    "freshbox-delete-product",
  ]
}
