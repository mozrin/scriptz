#!/bin/bash
cd ~/Code/test_barrel || exit
find ./ -type f -name "exports_*.dart" -exec rm {} +
find ./ -type f -name "barrel.dart" -exec rm {} +

