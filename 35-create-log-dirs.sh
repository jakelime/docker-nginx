#!/bin/sh
# Ensure log directory exists at runtime (even if volume is empty)
mkdir -p /applogs/nginx
# Ensure correct permissions (nginx user usually runs worker processes)
chown -R nginx:nginx /applogs/nginx