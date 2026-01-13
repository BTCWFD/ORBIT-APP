# Orbit Cloud - Infrastructure as Code (GCP)
provider "google" {
  project = "orbit-saas-cloud"
  region  = "us-central1"
}

resource "google_cloud_workstations_config" "orbit_planet_config" {
  workstation_cluster_id = "orbit-cluster"
  workstation_config_id  = "orbit-planet-v1"
  location               = "us-central1"

  container {
    image = "gcr.io/orbit-saas-cloud/orbit-planet:latest"
    env = {
      "ORBIT_USER"     = "admin"
      "ORBIT_PASSWORD" = var.vnc_password
    }
  }

  persistent_directories {
    mount_path = "/home/orbituser"
    gce_pd {
      size_gb        = 50
      fs_type        = "ext4"
      reclaim_policy = "RETAIN"
    }
  }
}

variable "vnc_password" {
  description = "Password for VNC and MCP access"
  type        = string
  sensitive   = true
}

output "workstation_config" {
  value = google_cloud_workstations_config.orbit_planet_config.name
}
