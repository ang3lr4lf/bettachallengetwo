# Define el rol IAM para la replicación
resource "aws_iam_role" "replication" {
  count = length(var.s3_bucket_names)
  name  = "${element(var.s3_bucket_names, count.index)}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# Define la política IAM para la replicación
resource "aws_iam_policy" "replication" {
  count = length(var.s3_bucket_names)
  name  = "${element(var.s3_bucket_names, count.index)}-s3-replication-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetReplicationConfiguration",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold"
        ]
        Resource = [
          "${aws_s3_bucket.main[count.index].arn}",
          "${aws_s3_bucket.main[count.index].arn}/*",
          "${aws_s3_bucket.replica[count.index].arn}",
          "${aws_s3_bucket.replica[count.index].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = [
          "${aws_s3_bucket.main[count.index].arn}/*",
          "${aws_s3_bucket.replica[count.index].arn}/*"
        ]
      }
    ]
  })
}

# Vincula el rol de peplicacion con la politica de replicacion
resource "aws_iam_role_policy_attachment" "replication" {
  count      = length(var.s3_bucket_names)
  role       = aws_iam_role.replication[count.index].name
  policy_arn = aws_iam_policy.replication[count.index].arn
}

# Define el bucket S3 principal
resource "aws_s3_bucket" "main" {
  count  = length(var.s3_bucket_names)
  bucket = element(var.s3_bucket_names, count.index)
}

# Habilita o deshabilita el acceso publico al bucket principal segun sea requerido
resource "aws_s3_bucket_public_access_block" "main" {
  count                   = length(var.s3_bucket_names)
  bucket                  = aws_s3_bucket.main[count.index].id
  block_public_acls       = var.s3_private
  block_public_policy     = var.s3_private
  ignore_public_acls      = var.s3_private
  restrict_public_buckets = var.s3_private
}

# Cambia la configuracion por defecto para poder cargar ACLs en el bucket principal
resource "aws_s3_bucket_ownership_controls" "main" {
  count  = length(var.s3_bucket_names)
  bucket = aws_s3_bucket.main[count.index].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Define el acl del bucket principal como "public-read" o "private" segun sea requerido
resource "aws_s3_bucket_acl" "main" {
  count = length(var.s3_bucket_names)
  depends_on = [
    aws_s3_bucket_public_access_block.main,
    aws_s3_bucket_ownership_controls.main,
  ]
  bucket = aws_s3_bucket.main[count.index].id
  acl    = var.s3_private ? "private" : "public-read"
}

# Habilita el versioning en el bucket principal
resource "aws_s3_bucket_versioning" "main" {
  count  = length(var.s3_bucket_names)
  bucket = aws_s3_bucket.main[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Habilita el cifrado server side en el bucket principal
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = length(var.s3_bucket_names)
  bucket = aws_s3_bucket.main[count.index].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Configura el bucket principal como static web hosting cuando es requerido
resource "aws_s3_bucket_website_configuration" "main" {
  count  = var.s3_private ? 0 : length(var.s3_bucket_names)
  bucket = aws_s3_bucket.main[count.index].id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each = var.s3_bucket_policies

  # Solo se ejecuta si los bucket de origen tienen el versioning habilitado
  depends_on = [aws_s3_bucket_versioning.main]
  bucket     = each.key

  dynamic "rule" {
    for_each = each.value.life_cycle_rules
    iterator = rule

    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try([rule.abort_incomplete_multipart_upload_days], [])

        content {
          days_after_initiation = try(rule.value.abort_incomplete_multipart_upload_days, null)
        }
      }

      dynamic "transition" {
        for_each = try([rule.value.transition], [])

        content {
          date          = try(transition.value.date, null)
          days          = try(transition.value.days, null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = try([rule.value.expiration], [])

        content {
          date                         = try(expiration.value.date, null)
          days                         = try(expiration.value.days, null)
          expired_object_delete_marker = try(expiration.value.expired_object_delete_marker, null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = try(flatten([rule.value.noncurrent_version_transition]), [])

        content {
          newer_noncurrent_versions = try(noncurrent_version_transition.value.newer_noncurrent_versions, null)
          noncurrent_days           = try(noncurrent_version_transition.value.noncurrent_days, null)
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try([rule.value.noncurrent_version_expiration], [])

        content {
          newer_noncurrent_versions = try(noncurrent_version_expiration.value.newer_noncurrent_versions, null)
          noncurrent_days           = try(noncurrent_version_expiration.value.noncurrent_days, null)
        }
      }

      dynamic "filter" {
        for_each = try([rule.value.filter], [])

        content {
          prefix                   = try(filter.value.prefix, null)
          object_size_greater_than = try(filter.value.object_size_greater_than, null)
          object_size_less_than    = try(filter.value.object_size_less_than, null)
        }
      }
    }
  }
}

# Define el bucket S3 replica (para Disaster Recovery)
resource "aws_s3_bucket" "replica" {
  count    = length(var.s3_bucket_names)
  provider = aws.replica
  bucket   = "${element(var.s3_bucket_names, count.index)}.replica"
}

# Habilita o deshabilita el acceso publico al bucket destino segun sea requerido
resource "aws_s3_bucket_public_access_block" "replica" {
  count                   = length(var.s3_bucket_names)
  provider                = aws.replica
  bucket                  = aws_s3_bucket.replica[count.index].id
  block_public_acls       = var.s3_private
  block_public_policy     = var.s3_private
  ignore_public_acls      = var.s3_private
  restrict_public_buckets = var.s3_private
}

# Cambia la configuracion por defecto para poder cargar ACLs en el bucket destino
resource "aws_s3_bucket_ownership_controls" "replica" {
  count    = length(var.s3_bucket_names)
  provider = aws.replica
  bucket   = aws_s3_bucket.replica[count.index].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Define el acl del bucket destino como "public-read" o "private" segun sea requerido
resource "aws_s3_bucket_acl" "acl_replica" {
  count    = length(var.s3_bucket_names)
  provider = aws.replica
  depends_on = [
    aws_s3_bucket_public_access_block.replica,
    aws_s3_bucket_ownership_controls.replica,
  ]
  bucket = aws_s3_bucket.replica[count.index].id
  acl    = var.s3_private ? "private" : "public-read"
}

# Habilita el versioning en el bucket destino
resource "aws_s3_bucket_versioning" "replica" {
  count    = length(var.s3_bucket_names)
  provider = aws.replica
  bucket   = aws_s3_bucket.replica[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Habilita el cifrado server side en el bucket principal
resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  count    = length(var.s3_bucket_names)
  provider = aws.replica
  bucket   = aws_s3_bucket.replica[count.index].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Configura el bucket destino como static web hosting cuando es requerido
resource "aws_s3_bucket_website_configuration" "replica" {
  count    = var.s3_private ? 0 : length(var.s3_bucket_names)
  provider = aws.replica
  bucket   = aws_s3_bucket.replica[count.index].id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "replica" {
  for_each = var.s3_bucket_policies

  # Solo se ejecuta si los bucket de origen tienen el versioning habilitado
  depends_on = [aws_s3_bucket_versioning.replica]
  provider   = aws.replica
  bucket     = "${each.key}.replica"

  dynamic "rule" {
    for_each = each.value.life_cycle_rules
    iterator = rule

    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try([rule.abort_incomplete_multipart_upload_days], [])

        content {
          days_after_initiation = try(rule.value.abort_incomplete_multipart_upload_days, null)
        }
      }

      dynamic "transition" {
        for_each = try([rule.value.transition], [])

        content {
          date          = try(transition.value.date, null)
          days          = try(transition.value.days, null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = try([rule.value.expiration], [])

        content {
          date                         = try(expiration.value.date, null)
          days                         = try(expiration.value.days, null)
          expired_object_delete_marker = try(expiration.value.expired_object_delete_marker, null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = try(flatten([rule.value.noncurrent_version_transition]), [])

        content {
          newer_noncurrent_versions = try(noncurrent_version_transition.value.newer_noncurrent_versions, null)
          noncurrent_days           = try(noncurrent_version_transition.value.noncurrent_days, null)
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try([rule.value.noncurrent_version_expiration], [])

        content {
          newer_noncurrent_versions = try(noncurrent_version_expiration.value.newer_noncurrent_versions, null)
          noncurrent_days           = try(noncurrent_version_expiration.value.noncurrent_days, null)
        }
      }

      dynamic "filter" {
        for_each = try([rule.value.filter], [])

        content {
          prefix                   = try(filter.value.prefix, null)
          object_size_greater_than = try(filter.value.object_size_greater_than, null)
          object_size_less_than    = try(filter.value.object_size_less_than, null)
        }
      }
    }
  }
}

# Configura los parametros para la replicacion entre el bucket principal y el destino
resource "aws_s3_bucket_replication_configuration" "replication" {
  count = length(var.s3_bucket_names)
  # Solo se ejecuta si los bucket de origen y destino tienen el versioning habilitado
  depends_on = [
    aws_s3_bucket_versioning.main,
    aws_s3_bucket_versioning.replica
  ]
  role   = aws_iam_role.replication[count.index].arn
  bucket = aws_s3_bucket.main[count.index].id
  rule {
    id       = "replicate-all-objects"
    status   = "Enabled"
    priority = 1
    filter {
      prefix = ""
    }
    destination {
      bucket        = aws_s3_bucket.replica[count.index].arn
      storage_class = "STANDARD"
    }
    # Incluye el este setting para conservar los delete_markers
    delete_marker_replication {
      status = "Enabled"
    }
    source_selection_criteria {
      replica_modifications {
        status = "Enabled"
      }
    }
  }
}
