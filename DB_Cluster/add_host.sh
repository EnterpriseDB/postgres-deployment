echo "Setting SSH Keys"
ssh-add ~/edb-postgres-cluster.pem
echo "Adding IPs"

ssh-keyscan -H 54.214.146.149 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ec2-54-214-146-149.us-west-2.compute.amazonaws.com
ssh-keyscan -H 44.235.118.147 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ec2-44-235-118-147.us-west-2.compute.amazonaws.com
ssh-keyscan -H 52.25.67.224 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R ec2-52-25-67-224.us-west-2.compute.amazonaws.com
