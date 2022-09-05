#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

PLONE_TEST_SLEEP=3
PLONE_TEST_TRIES=5

cname="plone-container-$RANDOM-$RANDOM"
cid="$(docker run -d --name "$cname" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

get() {
	docker run --rm -i \
		--link "$cname":plone \
		--entrypoint /plone/instance/bin/zopepy \
		"$image" \
		-c "from six.moves.urllib.request import urlopen, Request; request = Request('$1'); request.add_header('Accept-Language','pt-BR,en;q=0.5');print(urlopen(request).read())"
}

get_auth() {
	docker run --rm -i \
		--link "$cname":plone \
		--entrypoint /plone/instance/bin/zopepy \
		"$image" \
		-c "from six.moves.urllib.request import urlopen, Request; request = Request('$1'); request.add_header('Authorization', 'Basic $2'); request.add_header('Accept-Language','pt-BR,en;q=0.5');print(urlopen(request).read())"
}


. "$dir/../../retry.sh" --tries "$PLONE_TEST_TRIES" --sleep "$PLONE_TEST_SLEEP" get "http://plone:8080"

# Plone is up and running
[[ "$(get 'http://plone:8080')" == *"Portal Padrão"* ]]

# Create a Plone site
[[ "$(get_auth 'http://plone:8080/@@plone-addsite' "$(echo -n 'admin:admin' | base64)")" == *"Criar um novo site"* ]]
