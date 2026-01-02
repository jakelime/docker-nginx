#!/bin/sh
# Ensure log directory exists at runtime (even if volume is empty)
mkdir -p /datashare/www/static/
mkdir -p /datashare/www/media/
# Ensure correct permissions (nginx user usually runs worker processes)
chown -R nginx:nginx /datashare/www/