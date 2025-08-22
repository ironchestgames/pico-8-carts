
if [ -z "$1" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

butler push "$1"/vanquisher2.bin/vanquisher2_raspi.zip ironchestgames/virtuous-vanquisher-of-evil-2:raspi --userversion "$1"
butler push "$1"/vanquisher2.bin/vanquisher2_linux.zip ironchestgames/virtuous-vanquisher-of-evil-2:linux --userversion "$1"
butler push "$1"/vanquisher2.bin/vanquisher2_osx.zip ironchestgames/virtuous-vanquisher-of-evil-2:mac --userversion "$1"
butler push "$1"/vanquisher2.bin/vanquisher2_windows.zip ironchestgames/virtuous-vanquisher-of-evil-2:windows --userversion "$1"
