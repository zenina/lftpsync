#!/bin/bash - 
#===============================================================================
#
#          FILE: lftpsync.sh
# 
#         USAGE: ./lftpsync.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Nina L (nl), snarfsnaplen@gmail.com
#  ORGANIZATION: 
#       CREATED: 02/08/2018 19:43:46
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#!/bin/bash
### LFTP Parallel Transfer script ###
### Author: TheLinuxGirl aka Pink (2014)
###
### Description: Quick/Parallel transfer files or mirrors dir's, from a destination host, to a source path ###
### Read comments within the script, and adjust variables as necessary (specifically the variables at the top, unless you know what you are doing)
###
### Syntax ./lftp.sync.sh "<remote path>" "<local path>"
### Example : (quote paths to avoid space parsing)
###   	./lftp.sync.sh "files/SYNC/Sherlock.S02.HDTV.x264-GROUP" "/local/path/to/media/"
###
###


#########################################
### **** Configuration Variables **** ###

## Remote Host , and auth credentials##
host="host.hostname.com" 
user="johndoe"
passwd="supersecretpassword"

## LFTP session log location/format, and parallel threads (don't set too high) ##
session_log="${HOME}/var/log/lftp.txr.$(date +"%F.%s")"
p=5 ## parallel threads

########################################




### Grab arguments ###
file="${1}"
dst_dir="${2}"

### Init/Sanitization checking ###
init(){
if [[ -n $file ]]; then
	echo "Fetching Remote File $file with lftp"
else
	echo "Please list Remote file as first argument, starting from homedir root"
		echo "example: $0 files/PTP/sourcefile.mkv local/dest/dir"
	exit 1
fi
if [[ -d ${dst_dir} ]] ; then
	echo "Transferring to destination dir ${dest_dir}"
else
	echo "Please list Remote dir as 2nd argument"
		echo "example: $0 files/PTP/sourcefile.mkv local/dest/dir"
	exit 1
fi
}

status_check(){
## Set file and LFTP options based on some variables/checks ##

rfile="${file}"
rfile_name="$( echo ${rfile} | awk -F/ '{print $3 }' )"  ### sets filename to the 3rd string between the /'s (adjust $3, based on your remote sync directory) ###
dst_file="${dst_dir}/${rfile_name}"
status_file="${dst_file}.lftp-pget-status"

echo "=== Checking Transfer Status ==="
echo "Source File: ${rfile}"
echo "File Name: ${rfile_name}"
echo "File Destination: ${dst_file}"

## Check if destination file exists ##
file_exists=false
status_exists=false
if [[ -e "${dst_file}" ]]; then 
	echo "[STATUS]: Destination File Exists"
	ls -al "${dst_file}"
	file_exists=true 
	## Check if status file exists for resume ##
	if [[ -e "${status_file}" ]]; then
		echo "[STATUS]: LFTP Status File exists, setting options to resume transfer"
		ls -al "${status_file}"
		status_exists=true
	else
		echo "[STATUS]: LFTP Status file doesn't exist, but file does. Clobbering existing file"
		status_exists=false
	fi
else
	echo "[STATUS]: Destination File doesn't exist, using default options"
	file_exists=false
	status_exists=false
fi


## Set options based on lftp file status ##

if $file_exists && $status_exists ; then
	resume=true
	xfer_clob=off
	pget_cmd="pget -c -n ${p} \"${rfile}\""
	mirror_cmd="mirror -c -P5 --log=\"${session_log}\" -L \"${rfile}\" \"${dst_dir}\""

else
	xfer_clob=on
	pget_cmd="pget -n ${p} \"${rfile}\""
	mirror_cmd="mirror -P5 --log=\"${session_log}\" -L \"${rfile}\" \"${dst_dir}\""


fi

#################################
# ===== Other options ==========
#	set file:charset UTF-8
#	set cmd:interactive true
#	set fish:shell /bin/bash
#################################

}

################################


transfer(){
echo "==== TRANSFER ===="
echo "[!] Transfer Log: $session_log " 
echo "[!] Starting Download of ${rfile} file's will download to $dst_dir "
if $resume ; then
	echo "[!] Resuming transfer of existing file ${dst_file}"
fi

lftp -u ${user},${passwd} ${host}<<EOF
set xfer:log 1
set xfer:log-file ${session_log}
set xfer:clobber $xfer_clob
set cmd:save-rl-history true
set color:use-color true 
set xfer:destination-directory "${dst_dir}"
set mirror:parallel-transfer-count $p
${pget_cmd}
${mirror_cmd}
EOF
}

## Only Run to test option variables/output - dry run - does nothing ##
transfer_dry_run(){

echo "==== DRY RUN TEST ===="
echo "[DRY RUN]: Transfer Log: $session_log " 
echo "[DRY RUN]: Starting Download of ${rfile} file's will download to $dst_dir "

cat<<EOF
lftp -u ${user},${passwd} ${host}<<EOF
set xfer:log 1
set xfer:log-file ${session_log}
set xfer:clobber $xfer_clob
set cmd:save-rl-history true
set color:use-color true 
set xfer:destination-directory "${dst_dir}"
set mirror:parallel-transfer-count $p
${pget_cmd}
${mirror_cmd}
EOF
}

init
status_check
transfer

