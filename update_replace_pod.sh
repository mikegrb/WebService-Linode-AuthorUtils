#!/bin/sh

./gen-validation.pl -v | ./gen-pod.pl | ./replace-pod.pl
