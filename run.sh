#!/bin/bash

function finish {
	kill -9 `pidof sync_gateway`
}

trap finish SIGTERM SIGKILL

if [ ! -z $COUCHBASE_HOST ]; then
	for i in {30..0}; do
		if $(curl --output /dev/null --silent --head --fail $COUCHBASE_HOST:8091/pools/); then
		  break
		fi

		echo 'Couchbase init process in progress...'
		sleep 2
	done

	if [ "$i" = 0 ]; then
		echo >&2 'Couchbase init process failed.'
		exit 1
	fi

	echo 'Couchbase init process success. Run Sync gateway after 40s'
	sleep 40
fi

exec sync_gateway /config.json
