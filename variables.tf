variable "build_context" {
  description = "Path to the build directory containing the Dockerfile and context to build a Container Image"
  type        = string
  default     = null
}

variable "build_dockerfile" {
  description = "Path to the Dockerfile to build a Container Image"
  type        = string
  default     = null
}

variable "copy_repository_url" {
  description = "Image URL to copy to this repository"
  type        = string
  default     = null
}

variable "create" {
  description = "Creates this repository"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the image repository"
  type        = string
}

variable "tags" {
  description = "Tags for created resources"
  type        = map(string)
  default     = {}
}
