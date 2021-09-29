#!/bin/bash
#
# $1 batch prefix

scavetool x $1-*.sca $1-*.vec -o $1.csv

