variable "user" {
  description = "Username of user on remote. Usually `gcloud config list --format 'value(core.account)' | cut -d '@' -f 1`."
}

variable "project" {
  description = "Google Cloud project ID. Discoverable with `gcloud config list --format 'value(core.project)'`"
}

provider "google" {
  project      = var.project
}

variable "cpus" {
  description  = "Number of CPUs per VM. Valid values: 8, 16, 30, 60, 90"
  type         = number
  default      = 8
}

variable "machine_type" {
  description  = "GCP machine type code, e.g. c3-standard, c3d-standard, n2-standard. Out of those only c3d has the SSD option (per the database_ssd flag)."
  default      = "c3d-standard"
}

variable "database_ssd" {
  description  = "Does the database server have an ephemeral SSD? If 'true' then the machine type must support it."
  type = bool
  default = true
}

locals {
  database_type = var.database_ssd ? "${var.machine_type}-${var.cpus}-lssd" : "${var.machine_type}-${var.cpus}"
}

resource "random_id" "instance_id" {
  byte_length = 8
}

resource "google_compute_instance" "worker" {
  name         = "worker-${random_id.instance_id.hex}"
  machine_type = "${var.machine_type}-${var.cpus}"
  zone         = "europe-west1-d"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size = 100
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  provisioner "local-exec" {
    command = "scripts/bootstrap.sh ${google_compute_instance.worker.network_interface.0.access_config.0.nat_ip}"
  }
}

resource "google_compute_instance" "database" {
  name         = "database-${random_id.instance_id.hex}"
  machine_type = "${local.database_type}"
  zone         = "europe-west1-c"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size = 100
    }
  }	
  
  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  provisioner "local-exec" {
    command = "scripts/bootstrap.sh ${google_compute_instance.database.network_interface.0.access_config.0.nat_ip}"
  }
}

resource "google_compute_instance" "server" {
  depends_on = [google_compute_instance.database]
  name         = "server-${random_id.instance_id.hex}"
  machine_type = "${var.machine_type}-${var.cpus}"
  zone         = "europe-west1-c"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size = 100
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  provisioner "local-exec" {
    command = "scripts/bootstrap.sh ${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}"
  }
}

output "database_ip" {
    value = "${google_compute_instance.database.network_interface.0.access_config.0.nat_ip}"
}

output "database_name" {
    value = "${google_compute_instance.database.name}"
}

output "server_ip" {
    value = "${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}"
}

output "server_name" {
    value = "${google_compute_instance.server.name}"
}

output "worker_ip" {
    value = "${google_compute_instance.worker.network_interface.0.access_config.0.nat_ip}"
}

output "worker_name" {
    value = "${google_compute_instance.worker.name}"
}