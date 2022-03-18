resource "aws_ecr_repository" "this" {
  count = var.create == true ? 1 : 0

  name                 = var.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

data "aws_ecr_repository" "this" {
  count = var.create == false ? 1 : 0

  name = var.name
}
