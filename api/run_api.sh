#!/bin/bash

source /home/rihito/python3_env/bin/activate

nohup python3 /home/rihito/src/AquariumMonitoring/api/aquarium_api.py > /home/rihito/aquarium_api.log 2>&1 &
