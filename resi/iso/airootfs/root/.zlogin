# releng: skrip otomatis (parameter kernel script=...) lalu installer resi-shell di tty1
~/.automated_script.sh
if [[ $(tty) == /dev/tty1 ]]; then
  resi-iso-install || { echo; echo "Installer exited. Run 'resi-iso-install' to try again, or use this shell."; }
fi
