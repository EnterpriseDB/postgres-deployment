echo "Setting SSH Keys"
ssh-add -l ~/.ssh/id_rsa.pub
echo "Adding IPs"
ssh-keyscan -H 34.123.32.220 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R 34.123.32.220
ssh-keyscan -H 34.66.119.215 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R 34.66.119.215
ssh-keyscan -H 34.121.60.243 >> ~/.ssh/known_hosts
ssh-keygen -f ~/.ssh/known_hosts -R 34.121.60.243
