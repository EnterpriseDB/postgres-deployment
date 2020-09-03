bash ./lib_sh/keygen.sh
bash ./lib_sh/prereqs.sh
bash ./lib_sh/gcp-sdk.sh
if [ -z "$1" ] ; then
  bash ./lib_sh/pre-setup.sh
else
  bash ./lib_sh/pre-setup.sh "$1"
fi
bash ./lib_sh/pg-setup.sh
