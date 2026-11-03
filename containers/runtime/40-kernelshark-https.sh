#!/bin/sh

set -eu

https_config=/tmp/kernelshark-https.conf

case "${KERNELSHARK_HTTPS:-0}" in
	0)
		: > "$https_config"
		;;
	1)
		printf '%s\n' \
			'listen 8443 ssl;' \
			'ssl_certificate /etc/nginx/tls/tls.crt;' \
			'ssl_certificate_key /etc/nginx/tls/tls.key;' \
			'ssl_protocols TLSv1.2 TLSv1.3;' \
			'ssl_session_tickets off;' > "$https_config"
		;;
	*)
		echo "KERNELSHARK_HTTPS must be 0 or 1" >&2
		exit 1
		;;
esac
