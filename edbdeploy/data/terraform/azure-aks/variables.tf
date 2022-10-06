variable "appId" {
  description = "Azure Kubernetes Service Cluster service principal"
}

variable "password" {
  description = "Azure Kubernetes Service Cluster password"
}

variable "azureLocation" {
  description = "Azure Location"
}

variable "kClusterName" {
  description = "Azure Kubernetes Cluster Name"
}

variable "kEnvironmentName" {
  description = "Azure Kubernetes Environment Name"
}

variable "kNodeCount" {
  description = "Azure Kubernetes Node Count"
}

variable "kVmSize" {
  description = "Azure Kubernetes VM Size"
}

variable "kDiskOsSize" {
  description = "Azure Kubernetes VM OS Disk Size"
}
