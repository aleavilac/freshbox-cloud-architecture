variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo en los tags de todos los recursos."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC. /21 = 8 bloques /24 (necesitamos 6: 2 publicas + 2 App + 2 Data). Un /22 solo alcanza para 4 subredes /24 y no es suficiente para este diseño."
  type        = string
  default     = "10.0.0.0/21"
}

variable "azs" {
  description = "Zonas de disponibilidad a usar (Multi-AZ). Deben existir en la región configurada."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "data_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "single_nat_gateway" {
  description = "true = 1 solo NAT Gateway (ahorro de costos, apto para Academy Lab). false = 1 NAT por AZ (mas HA real, mas costo)."
  type        = bool
  default     = true
}
