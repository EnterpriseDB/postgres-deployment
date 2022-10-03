# Additional Windows Instructions

It is recommended to install `edb-deployment` in an WSL (Windows Subsystem for
Linux) environment.  It can be run in other virtual environments running Linux,
but there are dependencies that do not work in a Cygwin or pure Windows
environment.

Please be sure to review each section as each may or may not apply depending on
your usage.

## VirtualBox Installation

Download VirtualBox and the Extension Pack for Windows:
https://www.virtualbox.org/wiki/Downloads

## WSL Installation

Complete installation instructions can be found in Microsoft's documentation:
https://docs.microsoft.com/en-us/windows/wsl/install

Open an administrator command prompt and run the install command:

```shell
wsl --install
```

The default Ubuntu distribution will work for setting up `edb-deployment`.

## Vagrant Installation

Vagrant is only required if VirtualBox is going to be used locally on your
system.  It is not required for use with any cloud vendor.

Vagrant does not need to be installed in Windows, but needs to be installed in
the WSL environment.  Complete installation notes can be found in Vagrant's
documentation: https://www.vagrantup.com/docs/other/wsl

Two environment variables needs to set in order for Vagrant to access the host
Windows file system, and to be able to VirtualBox.

```shell
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"
```

The following instructions are taken from Vagrant's documentation for
installing in Ubuntu.

```shell
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install vagrant
```

Install additional plugins from the shell to enable shared folders and
workaround a bug to enable the `vagrant ssh` command on Windows:

```shell
 vagrant plugin install vagrant_guest
 vagrant plugin install virtualbox_WSL2
```

Vagrant storing its insecure SSH key on an NTFS file system causes some
additional issues with various Vagrant commands that try to ssh with the
insecure private key.  Create the file `/etc/wsl.conf` in the WSL environment
with the following contents:

```
# Enable extra metadata options by default
[automount]
enabled = true
root = /mnt/
options = "metadata,umask=77,fmask=11"
mountFsTab = false
```

Then restart WSL with the following command in an elevated Powershell:

```shell
Restart-Service -Name "LxssManager"
```

## Manual `edb-deployment` Setup

`edb-deployment` stores its files in `~/.edb-deployment` but the file system
used for WSL is not compatible with Vagrant.

Move or create `~/.edb-deployment`, depending on whether `edb-deployment` has
created the directory already, directory to `/mnt/c/` and create a symlink.
Anywhere on `/mnt/c` should be acceptable, but here is a specific example to
move the directory and create a symlink.

```
mv ~/.edb-deployment /mnt/c
ln -s /mnt/c/.edb-deployment ~/.edb-deployment
```
