#!/bin/sh
# Ensure log directory exists at runtime (even if volume is empty)
mkdir -p /datalogs/nginx
# Ensure correct permissions (nginx user usually runs worker processes)
chown -R nginx:nginx /datalogs/nginx