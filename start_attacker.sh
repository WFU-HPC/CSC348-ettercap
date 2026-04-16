#!/bin/bash

rm /var/lib/cni/networks/1234567890/*

apptainer shell --net --network 1234567890 --network-args "portmap=5901:5901/tcp" --hostname seed-container --dns 8.8.8.8 --add-caps NET_RAW,NET_ADMIN ettercap.sif
