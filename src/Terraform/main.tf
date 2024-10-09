terraform {
  required_version = ">= 1.0"
  backend "local" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project
  region = var.region
}

resource "google_storage_bucket" "data-lake-bucket" {
  name          = local.data_lake_bucket
  location      = var.region

  # Optional, but recommended settings:
  storage_class = var.storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled     = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 7  // days
    }
  }

  force_destroy = true
}

resource "google_storage_bucket" "events-data-bucket-storage" {
  location = var.region
  name     = "${local.events_bucket}"

  storage_class = var.storage_class
  uniform_bucket_level_access = true


  force_destroy = true
}

resource "google_storage_bucket_object" "receipts_pictures" {
  bucket = local.data_lake_bucket
  name   = "receipts_pictures/"
  content = " "
}

resource "google_artifact_registry_repository" "ocr-repo" {
  location      = var.region
  repository_id = "ocr-api"
  format        = "DOCKER"
}

# Build a Docker image
resource "null_resource" "build-image" {
  triggers = {
    dockerfile = filemd5("${var.project_path}/src/Dockerfile")
  }
  provisioner "local-exec" {
    command = "docker build -t ${var.image_name} ${var.project_path}/src"
  }
}

# Push the Docker image to Artifact Registry
resource "null_resource" "push-image" {
  depends_on = [null_resource.build-image]

  provisioner "local-exec" {
    command = "docker tag ${var.image_name} ${google_artifact_registry_repository.ocr-repo.location}-docker.pkg.dev/${google_artifact_registry_repository.ocr-repo.project}/${google_artifact_registry_repository.ocr-repo.repository_id}/${var.image_name}"
  }
  provisioner "local-exec" {
    command = "docker push ${google_artifact_registry_repository.ocr-repo.location}-docker.pkg.dev/${google_artifact_registry_repository.ocr-repo.project}/${google_artifact_registry_repository.ocr-repo.repository_id}/${var.image_name}"
  }
}

resource "google_cloud_run_v2_service" "default" {
  name = "ocr-agent-api"
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"
  depends_on = [null_resource.push-image]
  template {
    scaling {
      min_instance_count = 2
      max_instance_count = 10
    }
    containers {
      image = "${google_artifact_registry_repository.ocr-repo.location}-docker.pkg.dev/${google_artifact_registry_repository.ocr-repo.project}/${google_artifact_registry_repository.ocr-repo.repository_id}/${var.image_name}"
      ports {
        container_port = 11434
      }
      resources {
        limits = {
          cpu    = "4"
          memory = "16Gi"
        }
      }
    }

  }

}

data "google_iam_policy" "noauth" {
   binding {
     role = "roles/run.invoker"
     members = ["allUsers"]
   }
 }

 resource "google_cloud_run_service_iam_policy" "noauth" {
   location    = google_cloud_run_v2_service.default.location
   project     = google_cloud_run_v2_service.default.project
   service     = google_cloud_run_v2_service.default.name

   policy_data = data.google_iam_policy.noauth.policy_data
 }

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.bq_dataset
  project    = var.project
  location   = var.region
}

resource "google_bigquery_table" "default" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_id
  schema = file("schema.json")
  deletion_protection = false
}

resource "google_storage_bucket_object" "archive" {
  name   = "main.zip"
  bucket = "${google_storage_bucket.data-lake-bucket.name}"
  source = "main.zip"
}

resource "google_cloudfunctions_function" "function" {
  name    = "image_reader"
  description = "This the CF for reading image"
  runtime = "python310"

  available_memory_mb = 4096
  source_archive_bucket = google_storage_bucket.data-lake-bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  timeout = 480

  entry_point = "main"
  environment_variables = {
    LLAMA="${google_cloud_run_v2_service.default.uri}/api/generate"
    PROJECT_ID=var.project
    SOURCE="GCS"
    TABLE_ID = var.table_id
    DATASET_ID = var.bq_dataset
  }

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.events-data-bucket-storage.name
  }

}

# Build a Docker image
resource "null_resource" "build-file-uploader-image" {
  triggers = {
    dockerfile = filemd5("${var.project_path}/src/Service/Dockerfile")
  }
  provisioner "local-exec" {
    command = "docker build -t ${var.file_uploader_image_name} ${var.project_path}/src/Service"
  }
}

# Push the Docker image to Artifact Registry
resource "null_resource" "push-file-uploader-image" {
  depends_on = [null_resource.build-file-uploader-image]

  provisioner "local-exec" {
    command = "docker tag ${var.file_uploader_image_name} ${google_artifact_registry_repository.ocr-repo.location}-docker.pkg.dev/${google_artifact_registry_repository.ocr-repo.project}/${google_artifact_registry_repository.ocr-repo.repository_id}/${var.file_uploader_image_name}"
  }
  provisioner "local-exec" {
    command = "docker push ${google_artifact_registry_repository.ocr-repo.location}-docker.pkg.dev/${google_artifact_registry_repository.ocr-repo.project}/${google_artifact_registry_repository.ocr-repo.repository_id}/${var.file_uploader_image_name}"
  }
}

resource "google_cloud_run_v2_service" "file_uploader" {
  name = "file-uploader-api"
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"
  depends_on = [null_resource.push-file-uploader-image]
  template {
    scaling {
      min_instance_count = 1
      max_instance_count = 5
    }
    containers {
      env {
        name = "PROJECT_ID"
        value = var.project
      }
      env {
        name = "BUCKET"
        value = local.events_bucket
      }
      image = "${google_artifact_registry_repository.ocr-repo.location}-docker.pkg.dev/${google_artifact_registry_repository.ocr-repo.project}/${google_artifact_registry_repository.ocr-repo.repository_id}/${var.file_uploader_image_name}"
      ports {
        container_port = 8000
      }
      resources {
        limits = {
          cpu    = "2"
          memory = "8Gi"
        }
      }
    }

  }

}
 resource "google_cloud_run_service_iam_policy" "noauth_file_uploader" {
   location    = google_cloud_run_v2_service.file_uploader.location
   project     = google_cloud_run_v2_service.file_uploader.project
   service     = google_cloud_run_v2_service.file_uploader.name

   policy_data = data.google_iam_policy.noauth.policy_data
 }

output "cloud_run_instance_url" {
  value = google_cloud_run_v2_service.file_uploader.uri
}
