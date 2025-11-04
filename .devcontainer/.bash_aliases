# Create Helper Functions

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

##### Add your changes below here.