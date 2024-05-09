#!/usr/bin/env bash

networksetup -getairportnetwork en0 | sed -n "s/^.* Network: //p"
