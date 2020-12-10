variable "instance_count" {}
variable "pem_instance_count" {}
variable "synchronicity" {}
variable "instance_name" {}
variable "vm_type" {}
variable "vm_disk_type" {}
variable "vm_disk_size" {}
variable "volume_count" {}
variable "volume_disk_type" {}
variable "volume_disk_size" {}
variable "network_name" {}
variable "subnetwork_name" {}
variable "subnetwork_region" {}
variable "os" {}
variable "ssh_user" {}
variable "ssh_key_location" {}
variable "ansible_pem_inventory_yaml_filename" {}
variable "os_csv_filename" {}
variable "add_hosts_filename" {}
variable "full_private_ssh_key_path" {}


data "google_compute_zones" "available" {
  region = var.subnetwork_region
}


resource "google_compute_instance" "vm" {
  count        = var.instance_count
  name         = (var.pem_instance_count == "1" && count.index == 0 ? format("%s-%s", var.instance_name, "pemserver") : (var.pem_instance_count == "0" && count.index == 1 ? format("%s-%s", var.instance_name, "primary") : (count.index > 1 ? format("%s-%s%s", var.instance_name, "standby", count.index) : format("%s-%s%s", var.instance_name, "primary", count.index))))
  machine_type = var.vm_type

  #zone = data.google_compute_zones.available.names[count.index < 3 ? count.index : 2]
  zone = data.google_compute_zones.available.names[0]

  tags = [
    format("%s-%s", var.network_name, "firewall-ssh"),
    format("%s-%s", var.network_name, "firewall-http"),
    format("%s-%s", var.network_name, "firewall-https"),
    format("%s-%s", var.network_name, "firewall-icmp"),
    format("%s-%s", var.network_name, "firewall-postgresql"),
    format("%s-%s", var.network_name, "firewall-epas"),
    format("%s-%s", var.network_name, "firewall-efm"),
    format("%s-%s", var.network_name, "firewall-openshift-console"),
    format("%s-%s", var.network_name, "firewall-secure-forward"),
  ]

  boot_disk {
    initialize_params {
      image = var.os
      type  = var.vm_disk_type
      size  = var.vm_disk_size
    }
  }

  network_interface {
    subnetwork = var.network_name

    access_config {
      // Ephemeral IP
    }

  }

  # provisioner "remote-exec" {
  #   #script = "../../terraform/gcloud/environments/compute/setup_volumes.sh"

  #   inline = [
  #     "touch ~/temp.txt",
  #   ]

  #   connection {
  #     type        = "ssh"
  #     user        = var.ssh_user
  #     timeout     = "500s"
  #     private_key = file(var.full_private_ssh_key_path)
  #     host        = self.network_interface[0].access_config[0].nat_ip
  #   }
  # }

  # lifecycle {
  #   ignore_changes = [attached_disk]
  # }

  # metadata = {
  #   startup-script-custom = ""
  # }

  #metadata_startup_script = file("../../terraform/gcloud/environments/compute/setup_volumes.sh")

  # scheduling {
  #   automatic_restart =  true
  # }

  # provisioner "file" {
  #   source      = "../../terraform/gcloud/environments/compute/setup_volumes.sh"
  #   destination = "~/setup_volumes.sh"
  # }

  # provisioner "remote-exec" {
  #   script = file("../../terraform/gcloud/environments/compute/setup_volumes.sh")
  #   #inline = ["~/setup_volumes.sh"]

  #   connection {
  #     type = "ssh"
  #     user = var.ssh_user
  #     #host        = element(google_compute_instance.vm.*.nat_ip, floor(count.index / length(var.volume_count)))
  #     host        = google_compute_instance.vm[count.index].*.nat_ip
  #     private_key = file(var.full_private_ssh_key_path)
  #   }
  # }

}

resource "google_compute_disk" "volumes" {
  #count = var.volume_count
  count = var.instance_count * var.volume_count
  name  = format("%s-%s", var.network_name, count.index)
  type  = var.volume_disk_type
  size  = var.volume_disk_size
  zone  = data.google_compute_zones.available.names[0]

  depends_on = [google_compute_instance.vm]
}

resource "google_compute_attached_disk" "vm_attached_disk" {
  count    = var.instance_count * var.volume_count
  disk     = element(google_compute_disk.volumes.*.id, count.index)
  instance = element(google_compute_instance.vm.*.id, count.index)

  depends_on = [google_compute_disk.volumes]

  provisioner "remote-exec" {
    script = "../../terraform/gcloud/environments/compute/setup_volumes.sh"

    # inline = [
    #   "touch ~/temp.txt",
    # ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      timeout     = "500s"
      private_key = file(var.full_private_ssh_key_path)
      #host        = self.network_interface[0].access_config[0].nat_ip
      host = google_compute_instance.vm[count.index].network_interface[0].access_config[0].nat_ip
    }
  }

}

resource "null_resource" "provisioner" {
  count = var.instance_count

  provisioner "remote-exec" {
    script = "../../terraform/gcloud/environments/compute/setup_volumes.sh"

    # inline = [
    #   "touch ~/temp.txt",
    # ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      timeout     = "500s"
      private_key = file(var.full_private_ssh_key_path)
      #host        = self.network_interface[0].access_config[0].nat_ip
      host = element(google_compute_instance.vm[count.index].network_interface[0].access_config[0].nat_ip, floor(count.index / length(var.volume_count)))
      #host        = google_compute_instance.vm[count.index].network_interface[0].access_config[0].nat_ip
      agent = false

    }
  }

  depends_on = [google_compute_disk.volumes, google_compute_attached_disk.vm_attached_disk]
}