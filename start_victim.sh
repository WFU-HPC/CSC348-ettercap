#!/bin/bash

apptainer shell --net --network 1234567890 --network-args "portmap=5902:5902/tcp" --hostname seed-container --dns 8.8.8.8 ettercap.sif
