#!/bin/sh
echo "lines=$(wc -l < kp.err) KL=$(grep -c '^KL' kp.err) Qask=$(grep -c '^Q	ask' kp.err) first=$(head -c 200 kp.err | tr '\n' '|')"
