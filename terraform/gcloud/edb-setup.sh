bash ./keygen.sh
bash ./prereqs.sh
bash ./gcp-sdk.sh
if [ -z "$1" ] ; then
  bash ./pre-setup.sh
else
  bash ./pre-setup.sh "$1"
fi
bash ./pg-setup.sh
