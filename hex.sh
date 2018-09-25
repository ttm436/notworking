#!/bin/bash
while sleep 0.$((RANDOM%7+1)); do head -c200 /dev/urandom | od -An -N 191 -x | grep -E --color "([[:alpha:]][[:digit:]]){2}"; done
