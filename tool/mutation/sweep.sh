#!/bin/sh
set -e
here=$(cd "$(dirname "$0")" && pwd -W 2>/dev/null || pwd)
repo=$(cd "$here/../.." && pwd -W 2>/dev/null || pwd)
workers=${1:-8}
cases=${2:-300}
records=$3
tests=${RUN_TESTS:-0}
out=${OUT:-results}
mkdir -p "$here/$out"
i=0
while [ $i -lt "$workers" ]; do
  MSYS_NO_PATHCONV=1 docker run --rm --memory=1200m --entrypoint sh -e RUN_TESTS="$tests" \
    -v "$repo":/src:ro -v kdmut$i:/work \
    -v "$here":/m -v "$here/$out":/out -v "$here/run.sh":/run.sh:ro \
    kosherjava-parity-linux /m/mut.sh $i "$workers" "$cases" $records > "$here/$out/worker$i.log" 2>&1 &
  i=$((i + 1))
done
wait
cat "$here/$out"/mut*.jsonl | grep -o '"status":"[a-z]*"' | sort | uniq -c
