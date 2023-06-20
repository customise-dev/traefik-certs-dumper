#!/bin/bash
set -euo pipefail
set -x

if (( "$#" != 3 )); then
    echo "Illegal number of arguments, need 3 arguments: <output of docker/metadata-action> <desired Docker image name> <labels>" >&2
    exit 1
fi

readonly __docker_image_name="$2"

NEW_IMAGE_NAMES=()
LOCAL_IMAGE_NAMES=()
while IFS=$'\n'; read -ra LOCAL_TAGS; do
    for i in "${LOCAL_TAGS[@]}"; do
        __tag=$(cut -d ':' -f2 <<< "$i")
        LOCAL_IMAGE_NAMES+=("$i")
        NEW_IMAGE_NAMES+=("$__docker_image_name:$__tag")
    done
done <<< "$1"

echo "${NEW_IMAGE_NAMES[@]}"

for image_name in "${NEW_IMAGE_NAMES[@]}"; do
    docker buildx imagetools create --append -t "$image_name" "${LOCAL_IMAGE_NAMES[@]}" localhost:5000/traefik-certs-dumper:armhf
    docker buildx imagetools inspect --raw "$image_name" | jq --argjson annotations "$3" '.annotations = $annotations' > descr.json
    docker buildx imagetools create --append -t "$image_name" -f descr.json "$image_name"
done

exit 0
