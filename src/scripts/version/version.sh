#!/bin/bash

# version.sh — Get the versions for everything.
# by Moztopia
# version 0.0.1

version() {
  echo "lsb_release -a"
  echo ""
  lsb_release -a
  echo ""
  echo "cat /etc/os-release"
  echo ""
  cat /etc/os-release
  echo ""
  echo "uname -a"
  echo ""
  uname -a
}