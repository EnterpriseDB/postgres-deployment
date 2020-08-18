# AWS CLI v2 Installation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Create Symlinks
sudo ln -s -f /usr/local/aws-cli/v2/2.0.38/bin/aws /usr/bin/aws
sudo ln -s -f /usr/local/aws-cli/v2/2.0.38/bin/aws_completer /usr/bin/aws_completer
