#!/bin/bash
set -e

$CKAN_VENV/bin/ckan -c ${CKAN_CONFIG}/production.ini run --host 0.0.0.0
