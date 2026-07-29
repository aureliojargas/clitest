# XML metachars and a non-printable char (ESC), in both command and output

$ printf 'AT&T <b>"quoted"</b>\033[m\n'  #=> nope
