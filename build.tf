locals {
  registry       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  repository_url = var.create ? aws_ecr_repository.this[0].repository_url : data.aws_ecr_repository.this[0].repository_url
  #  repository_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.name}:latest"

  // Copy an image from a repository if specified, else build it from the given context.
  build = var.copy_repository_url == null && var.build_context != null
  copy  = var.copy_repository_url != null
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "local_file" "container_dockerfile" {
  count    = var.build_context != null ? 1 : 0
  filename = var.build_dockerfile != null ? var.build_dockerfile : "${var.build_context}/Dockerfile"
}

resource "null_resource" "copy_image" {
  count = local.copy ? 1 : 0

  provisioner "local-exec" {
    command     = <<EOF
      docker pull "${var.copy_repository_url}" && \
      docker tag "${var.copy_repository_url}" "${local.repository_url}"
    EOF
    environment = {
      AWS_REGION = data.aws_region.current.name
    }
  }

  triggers = {
    redeployment = sha256(join(",", [
      var.copy_repository_url,
    ]))
  }

  depends_on = [data.local_file.container_dockerfile]
}

resource "null_resource" "build_image" {
  count = local.build ? 1 : 0

  provisioner "local-exec" {
    command     = <<EOF
      docker build --tag "${var.name}:latest" . && \
      docker tag "${var.name}:latest" "${local.repository_url}"
    EOF
    working_dir = "${var.build_context}/"
    environment = {
      AWS_REGION = data.aws_region.current.name
    }
  }

  triggers = {
    redeployment = sha256(join(",", [
      jsonencode(data.local_file.container_dockerfile),
    ]))
  }

  depends_on = [data.local_file.container_dockerfile]
}

resource "null_resource" "push_image" {
  count = (local.copy || local.build) ? 1 : 0

  provisioner "local-exec" {
    command     = <<EOF
      aws ecr get-login-password --region ${data.aws_region.current.name} | \
        docker login --username AWS --password-stdin ${local.registry} && \
      docker push "${local.repository_url}"
    EOF
    environment = {
      AWS_REGION = data.aws_region.current.name
    }
  }

  triggers = {
    redeployment = sha256(join(",", [
      local.build ? jsonencode(data.local_file.container_dockerfile) : var.copy_repository_url,
      local.build ? jsonencode(null_resource.build_image[0]) : jsonencode(null_resource.copy_image[0]),
    ]))
  }

  depends_on = [
    null_resource.build_image,
    null_resource.copy_image,
  ]
}
