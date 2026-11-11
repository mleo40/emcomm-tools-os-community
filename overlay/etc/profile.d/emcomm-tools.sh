# EmComm Tools PATH entries.
#
# Debian's /etc/profile resets PATH for non-root login shells, which drops the
# entries set in /etc/environment. Add them back, in the r7 order, once.
case ":${PATH}:" in
  *":/opt/emcomm-tools/bin:"*) ;;
  *) PATH="/opt/emcomm-tools/bin:${PATH}" ;;
esac
for _et_dir in /usr/local/sbin /usr/sbin /sbin; do
  case ":${PATH}:" in
    *":${_et_dir}:"*) ;;
    *) PATH="${PATH}:${_et_dir}" ;;
  esac
done
unset _et_dir
export PATH
