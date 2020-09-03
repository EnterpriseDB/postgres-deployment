echo "Setting SSH Keys"
ssh-add ~/edb-postgres-cluster.pem
echo "Adding IPs"

ssh-keyscan -H 52.26.10.168 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ec2-52-26-10-168.us-west-2.compute.amazonaws.com
ssh-keyscan -H 34.213.24.213 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ec2-34-213-24-213.us-west-2.compute.amazonaws.com
ssh-keyscan -H 35.165.114.158 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ec2-35-165-114-158.us-west-2.compute.amazonaws.com
ssh-keyscan -H 54.188.24.191 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ec2-54-188-24-191.us-west-2.compute.amazonaws.com
