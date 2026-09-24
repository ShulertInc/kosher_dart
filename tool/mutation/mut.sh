set -e
export PUB_CACHE=/work/.pub-cache
SETUP_ONLY=1 sh /run.sh
rm -rf /work/example
(cd /work && dart pub get >/dev/null)
cd /m
exec dart mutate.dart /work "$1" "$2" "/out/mut$1.jsonl" "$3" $4
