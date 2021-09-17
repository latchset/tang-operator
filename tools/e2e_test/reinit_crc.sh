#!/bin/bash
crc stop -f
crc delete -f
crc setup
crc start -p public_pull_secret.txt
