#!/bin/bash

source /home/rihito/bigquery_env/bin/activate

python3 /var/lib/aquarium_monitoring/aquarium_monitoring.py

deactivate
