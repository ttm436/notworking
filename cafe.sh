#!/bin/bash
cat /dev/random | hexdump | grep "ca fe"
