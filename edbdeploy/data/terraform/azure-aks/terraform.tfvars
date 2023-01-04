# Get the appId and password with az cli command:
# az ad sp create-for-rbac --skip-assignment
appId            = "<your_app_id>"
password         = "<your_password>"
azureLocation    = "East US 2"
kClusterName     = "EDB-CNP"
kEnvironmentName = "EDB-CNP"
kNodeCount       = 2
kVmSize          = "Standard_A2_v2"
kDiskOsSize      = 100
