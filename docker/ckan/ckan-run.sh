#!/bin/bash
set -e

$CKAN_VENV/bin/ckan -c ${CKAN_CONFIG}/ckan.ini run --host 0.0.0.0
