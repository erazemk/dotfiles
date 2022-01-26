#
# ~/.login
#

# Query terminal size; useful for serial lines.
if ( -x /usr/bin/resizewin ) /usr/bin/resizewin -z

# Start syncthing in background
syncthing >/dev/null &
clear
