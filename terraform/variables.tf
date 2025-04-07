variable "yc_token" {}
variable "cloud_id" {}
variable "folder_id" {}
variable "zone" {
  default = "ru-central1-a"
}
variable "subnet_id" {}
variable "image_id" {
  # Ubuntu 22.04 
  default = "fd8r7e7939o13595bpef"
}
