locals {
  data_lake_bucket = ""
  events_bucket = ""
}

variable "project" {
  description = "Your GCP Project ID"
  default = ""
}

variable "region" {
  description = "Region for GCP resources. Choose as per your location: https://cloud.google.com/about/locations"
  default = ""
  type = string
}

variable "storage_class" {
  description = "Storage class type for your bucket. Check official docs for more info."
  default = "STANDARD"
}

variable "bq_dataset" {
  description = "BigQuery Dataset that raw data (from GCS) will be written to"
  type = string
  default = "expenses"
}

variable "table_id" {
  description = "BigQuery Dataset that raw data (from GCS) will be written to"
  type = string
  default = "expense_report"
}
variable "service_account" {
  description = "OCR service account SA"
  type = string
  default = ""
}

variable "project_path" {
  description = "project path"
  type = string
  default = "expense-tracking"
}

variable "image_name" {
  description = "image name"
  type = string
  default = "ocr-agent-image"
}

variable "file_uploader_image_name" {
  description = "image name"
  type = string
  default = "file-uploader-image"
}


