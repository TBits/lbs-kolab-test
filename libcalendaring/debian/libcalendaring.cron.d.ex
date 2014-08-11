#
# Regular cron jobs for the libcalendaring package
#
0 4	* * *	root	[ -x /usr/bin/libcalendaring_maintenance ] && /usr/bin/libcalendaring_maintenance
