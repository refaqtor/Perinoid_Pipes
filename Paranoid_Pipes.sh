#!/usr/bin/env bash
## For license of this script try: Paranoid_Pipes --license
## For help with this script try: Paranoid_Pipes --help

## Security notices for the following functions
## Func_do_stuff_to_input : has commented lines that should remain commented

## Note : bellow variables maybe overwritten by supplying command line
##  options, ei --option=value or ---var_name=var_value
##  run -h or --help for help and use wisely.

## turn off history logging temporarily, note that the trap function will
##  History turns logging again on upon exiting or when trap is triggered.
echo "Turning off bash history for a moment..."
set +o history

## Assign name of this script and file path to variables for latter use
Var_script_dir="${0%/*}"
Var_script_name="${0##*/}"
Var_script_version='1'
Var_script_subversion='1476673946'
Var_script_title="${Var_script_name} v${Var_script_version}-${Var_script_subversion}"
## Grab the PID of this script in-case auto-backgrounding is selected
##  without also selecting to write-out custom named pipe listener script.
Var_script_pid="$$"
Var_script_pid=${Var_script_pid:-$BASHPID}
## Assign variable that functions may use to grab their own PID in-case
##  auto-backgrounding is selected as well as writing out custom named
##  pipe listener.
Var_subshell_pid="${BASH_SUBSHELL}"
## Refresh user name variable of current user running this script in case
##  we have to run commands selectively under a different user.
 : "${USER?}"
## Refresh user home directory variable for saving logs and script copies to
 : "${HOME?}"
Var_script_current_user="${USER}"
## Columns of terminal width, defaults to 80 if not readable
Var_columns_width="${COLUMNS:-80}"
## Variables that find file paths to required executables. Note these maybe useful
##  if using mounted read only binary directory, ie "tin-foil top-hat" levels of paranoia.
##  Or useful if attempting to "remote control" a chroot jailed file system from the host.
Var_chmod_exec_path="$(which chmod)"
Var_chown_exec_path="$(which chown)"
Var_echo_exec_path="$(which echo)"
Var_mkfifo_exec_path="$(which mkfifo)"
Var_cat_exec_path="$(which cat)"
Var_mkdir_exec_path="$(which mkdir)"
Var_mv_exec_path="$(which mv)"
Var_rm_exec_path="$(which rm)"
Var_tar_exec_path="$(which tar)"
Var_gpg_exec_path="$(which gpg)"
## Used for silencing output of loops, ei
# <command_to_silence> >${Var_dev_null} 2>&1 &
# <command_to_quite> &> ${Var_dev_null}
Var_dev_null="${Var_dev_null}"
## Save date command with seconds sense 1970 option for logs and messages that include timing info
Var_star_date=$(date -u +%s)

## Numerical regex variable bellow is used within user input parsing loop
##  to ensure variables that this script expects numbers to be contained
##  are only allowed to contain numbers if set at the command line.
Var_number_regex='[^0-9]'
## Non-symbol non-numerical regex variable bellow is used much like above
##  for only matching letters
Var_azAZ_regex='[^a-zA-Z]'
## Another for file paths, emails, and user permissions
Var_string_regex='[^a-zA-Z0-9_@,.:~\/]'

## The following two variables control the "loudness" of message output
##  and message logging, set them high during testing for error catching.
## Set to '0' to not output prior to parsing lines read from named pipe.
##  Set to '4' or greater for the loudest experience.
##  CLO --debug-level
Var_debugging="6"
#Var_debugging="4"
## Set to '0' to not log anything from this script run time or
##  set to '$((${Var_debugging}+1))' or greater to log every message
##  that would normally be printed to the terminal.
##  CLO --log-level
Var_logging="0"
#Var_logging="5"
## Set full file path and name to save messages. Note if not running
##  this script as 'root:root' then set permissions to '420' or '240'
##  and 'user:group' to something like 'LogReadUser:LogReadGroup'
##  the permissions of '6=read,write' so you may wish to set these
##  to different user groups with differing read/write permissions
##  on production server to prevent logs from being read by wrong
##  user/group. This file path is for internal script logs which may
##  or may not be written to depending on above value.
##  CLO --log-file-location
Var_log_file_name="${Var_script_dir}/${Var_script_name%.*}.log"
##  CLO --log-file-permissions
Var_log_file_permissions="660"
##  CLO --log-file-ownership
Var_log_file_ownership="${Var_script_current_user}:${Var_script_current_user}"
##  CLO --log-auto-delete-yn
Var_remove_script_log_on_exit_yn='yes'
## The last above variable if set to 'no' will allow debugging logs
##  to persist and be appended to if variables are otherwise unchanged
##  between repeated runs.

## Permissions to assign to following file name. Both are utilized
##  in 'mkfifo' commands. For production '420' ("4=read" & "2=write")
##  and 'PipeReadUser:PipeWriteGroup' should allow sufficient
##  permissions for data to pass only in desired directions. Both
##  users and groups should be non privileged in production as well.
##  CLO  --named-pipe-permissions
Var_pipe_permissions='600'
## User:Group permissions to assign to the following file name
##  CLO  --named-pipe-ownership
Var_pipe_ownership="${Var_script_current_user}:${Var_script_current_user}"
## Full file path and name without suffix of file to run 'mkfifo' command with
##  CLO --named-pipe-name
Var_pipe_file_name="${Var_script_dir}/${Var_script_name%.*}.pipe"
## Word or string that when written to the above file name will cause this or
## the written template to exit cleanly with the next variables command.
##  CLO --listener-quit-string
Var_pipe_quit_string="quit"
## Command to issue when script or template exits, leave set as is
## to have this script or written template auto clean up after itself
##  CLO <disabled>
Var_trap_command="${Var_rm_exec_path} -f ${Var_pipe_file_name}"

## GPG variables for encryption of input read from named pipe.
##  CLO --output-save-yn
Var_save_encryption_yn="yes"
## Note these following two variables are "fluff" for making '${Var_parsing_command}'
##  variable a little more readable/modifiable.
## To whom to encrypt individual lines and recognized files to?
##  CLO --output-gpg-recipient
Var_gpg_recipient="user@host.domain"
### Note the following two are temporarily assigned here
###  and then assigned for run time within [Func_check_args]
###  this is to prevent the above defaults from interfering.
## Options to use with above recipient?
##  CLO <disabled>
Var_gpg_recipient_options="--always-trust --armor --batch --encrypt --recipient ${Var_gpg_recipient}"
#Var_gpg_recipient_options="--always-trust --armor --batch --recipient ${Var_gpg_recipient} --encrypt"
## Note if your server has imported and assigned a trust value
##  to the recipient then remove '--always-trust' option from above!
## Command to use with internal variable "<(${_input_from_pipe_read})"
##  CLO <disabled>
Var_parsing_command="${Var_gpg_exec_path} ${Var_gpg_recipient_options}"

## Output file for above command to append to. Note if unset then output will be directed
##  to the terminal, ie this could flood your terminal if unset.
##  CLO --output-parse-name
Var_parsing_output_file="${Var_pipe_file_name%.*}.gpg"
## Output encrypted file to bellow directory; this script auto preserves
##  file names and appends '.gpg' to the end. Note no trailing slashes
##  for bellow path!
##  CLO --output-bulk-dir
Var_parsing_bulk_out_dir="${Var_script_dir}/Bulk_${Var_script_name%.*}"
## Some notes on above two variables, the first one '${Var_parsing_output_file}'
##  controls where individual lines are encrypted when read from named pipe
##  and the '${Var_parsing_bulk_out_dir}' variable controls what directory
##  recognized files will end up in, the file name is preserved aside from appending
##  a '~.gpg' suffix and are otherwise unmodified... hopefully...
## What file suffix to append to bulk output files?
##  Bellow variable modifies behavior commented above, ie if you wish for a different
##  file type to be appended to recognized files then place that bellow. Note for
##  decryption you may wish to completely unset bellow, ei "" or use '.log' as
##  one should unset previously suffixed '~.gpg' bulk files encrypted with another
##  custom named pipe listening script and the other should output files ready for
##  programs such as 'fail2ban' to watch.
##  CLO --output-bulk-suffix
Var_bulk_output_suffix=".gpg"

## Disable this when first testing your named pipe reader and
##  parsing log output variables. Enable to have output log
##  file size checked and rotated and/or emailed to sys-admin;
##  potentially with a different gpg key than the one defined above ;-)
##  CLO --output-rotate-yn
Var_log_rotate_yn="yes"
## Max log file size in 'bites' note this value is not checked
##  until the next variables value has been reached. Play with
##  these values to fine tune how often log files are checked
##  and have rotation actions taken.
##  CLO --output-rotate-max-bites
Var_log_max_size="4096"
## After how many lines of input should the log file have size check
##  and log file rotate values checked. If your server is busy then
##  set this to a much higher value to avoid constantly checking the
##  log file size and other variables bellow this one.
##  CLO --output-rotate-check-frequency
Var_log_check_frequency="100"
## Valid actions are [move|mv,compress-encrypt|encrypt,compress,remove|rm]
##  these actions take place in the order given and if encryption is enabled
##  then you must set the very next variable too. Actions maybe space ' '
##  separated or separated by comas ',' in the order you wish to have them
##  taken. Additional options if email is already setup are [encrypted-email]
##  and [compressed-email] which preforms the same action as [compress-encrypt]
##  or [compress] but also emails the log file as an attachment to the same
##  email address defined in '${Var_log_rotate_recipient}' variable bellow.
##  For testing the defaults bellow are good.
##  CLO --output-rotate-actions
Var_log_rotate_actions="compress-encrypt,remove-old"
#Var_log_rotate_actions="encrypted-email,remove-old"
## Valid public key ID of log file backups, note this maybe different than
##  the public key ID used to encrypt the parsed input read from named pipe.
##  This maybe useful if using the first key to encrypt stuff read by another
##  file system, ie firejail or chroot, that preforms auto firewall modification
##  of the service writing to this named pipe.
##  CLO --output-rotate-recipient
Var_log_rotate_recipient="user@host.domain"
#Var_log_rotate_recipient="${Var_gpg_recipient}"

## Set the next variable to valid empty file path to have this script save a copy
##  of current settings and script behavior to another file
##  CLO --copy-save-yn
Var_script_copy_save='no'
##  CLO --copy-save-name
Var_script_copy_name="${Var_script_dir}/disownable_pipe_listener.sh"
##  CLO --copy-save-permissions
Var_script_copy_permissions='100'
##  CLO --copy-save-ownership
Var_script_copy_ownership="${Var_script_current_user}:${Var_script_current_user}"
## The following two variables maybe used to parse for comments being passed
##  to named pipe. Leave enabled to prevent this script from duplicating '#'
##  comments or prepending '#' to other strings read.
##  CLO --output-pre-parse-yn
Var_preprocess_for_comments_yn="no"
## The following maybe a pipe "|" separated list of comment marks to search
##  the beginning of each line.
##  CLO --output-pre-parse-comment-string
Var_parsing_comment_pattern='\#*'
## Note the above two variables only apply to single lines read from named pipe
##  no per line processing in preformed on recognized files passed to named pipe.

## Note the following uses single quotes for initial assignments
##  to prevent the interpreting shell from expanding until called.
##  See very bottom of this script for examples on how this is used
##  and why single quotes are not included.
##  CLO --output-pre-parse-allowed-chars
Var_parsing_allowed_chars='[^a-zA-Z0-9 _.@!#%&:;$\/\^\-\"\(\)\{\}\\]'

## This magic setting enables shoving the reading loop into
##  a disowned subshell. If saving to template is also enabled
##  then when this script calls the written template then the
##  called template should auto disown itself. Note this value
##  is checked multiple times during this script setup phase.
##  Anything interpreted as 'yes' will also modify 'trap' order
##  of assignment, ei if enabled then trap is set within disowned
##  parsing loop instead of just prior to assigning more functions
##  than the messaging function and trap function.
##  CLO --disown-yn
Var_disown_parser_yn="yes"

## Variables that control the output color palate, note the following
##  use the 'echo -e "something to echo"' command to enable ANSI escape
##  codes, this also enables the contained string to preform new lines '\n'
##  and other features; be aware of what is allowed to be expanded when
##  using the '-e' with echo.
## Note commented color assignments are currently not used by this script
##  and are commented to keep 'shellcheck' *happier* with this script.
Var_color_red='\033[0:31m'
#Var_color_green='\033[0:32m'
#Var_color_yellow='\033[0:33m'
#Var_color_blue='\033[0:34m'
#Var_color_purple='\033[0:35m'
#Var_color_cyan='\033[0:36m'
#Var_color_gray='\033[0:37m'
Var_color_lred='\033[1:31m'
Var_color_lgreen='\033[1:32m'
Var_color_lyellow='\033[1:33m'
#Var_color_lblue='\033[1:34m'
Var_color_lpurple='\033[1:35m'
#Var_color_lcyan='\033[1:36m'
#Var_color_lgray='\033[1:37m'
Var_color_null='\033[0m'
##  Example of usage:
##   echo -e "${Var_color_lpurple}This should be light purple\n${Var_color_null}And this should be colorless."
## Currently the above are only used on messages that
##  include command line options set at script run-time.
##  Helps with debugging as this script can be loud.

## CLO --padding-enable-yn
Var_enable_padding_yn='no'
## CLO --padding-length
Var_padding_length='adaptive'
## CLO --padding-placement
Var_padding_placement='above'
#Var_padding_placement='above,bellow,append,prepend'
## CLO --source-var-file
Var_source_var_file=""
## CLO --save-options-yn
Var_save_options='no'
## CLO --save-variables-yn
Var_save_variables='no'

### Experimental variables and alternative variable examples
Var_authors_contact='strangerthanbland@gmail.com'

## Do the reverse of above encryption saving output to '${Var_pipe_file_name%.*}.log'
##  instead. Note doing this requires that you either have password caching
##  enabled for this scripts user or have a clear text password file or have
##  this script some how safely cache your private gpg key password...
##  generally frowned upon even if using sub keys. But this is also why
##  the log line-by-line key can be set different than that of the log
##  rotation encryption key, if setup with a chroot jail preforming log
##  encryption writing parsing and host OS preforming temporary decryption
##  for firewall modification automation (ie fail2ban) this may mitigate
##  privacy attacks on logged services by not keeping logs in clear-text
##  nor keeping large caches of encrypted logs on either host or jailed file
##  systems for attackers to slurp up.
#Var_gpg_decrypter="root"
#Var_gpg_decrypter_options="--batch --decrypt"
#Var_gpg_decrypter_options="--batch -u ${Var_gpg_decrypter} --decrypt"
#Var_parsing_command="${Var_gpg_exec_path} ${Var_gpg_decrypter_options}"
#Var_parsing_output_file="${Var_pipe_file_name%.*}.log"
#Var_bulk_output_suffix="log"

### START of scripted log/functions declarations modify bellow at your own risk!

## The following function takes messages passed to it from script run time
##  and based on user set debugging levels will either print or silence
##  certain types of messages from various levels of scripted logic.
Func_messages(){
	_message="$1"
	_debug_level="${2:-${Var_debugging}}"
	_log_level="${3:-${Var_logging}}"
	## Use echo to notify script user of various levels of information if user set debug level
	##  is either equal to or less than the values set by messages. Otherwise be silent.
	if [ "${Var_debugging}" = "${_debug_level}" ] || [ "${Var_debugging}" -gt "${_debug_level}" ]; then
		## Set colors of hash marks in messages based on differences in debugging levels.
		if [ "${Var_debugging}" = "${_debug_level}" ]; then
			_custom_color="${Var_color_lgreen}"
		elif [ "${Var_debugging}" -gt "${_debug_level}" ]; then
			_custom_color="${Var_color_lyellow}"
		else
			_custom_color="${Var_color_red}"
		fi
		## Note this ugly line is what makes messages line wrap at word
		##  boundaries. And shellcheck will complain about quoting use.
		##  The authors of this script believe it to be more prudent
		##  to spicificly quote the message text
#		_line_wrap_message=$(fold -sw "$((${Var_columns_width:-80}-8))" <<<"${_message}")
		_colorized_prefix="${Var_echo_exec_path} -en ${_custom_color}#${Var_color_null}DBL-${_debug_level}${_custom_color}#${Var_color_null}"
		_line_wrap_message=$(fold -sw "$((${Var_columns_width:-80}-8))" <<<"${_message}" | sed -e "s/^.*$/${_colorized_prefix} &/g")
#		_line_wrap_message=$(fold -sw $((${Var_columns_width}-8)) <<<"${_message}" | sed -e "s/^.*$/$(${Var_echo_exec_path} -en ${_custom_color}#${Var_color_null}DBL-${_debug_level}${_custom_color}#${Var_color_null}) &/g")
		${Var_echo_exec_path} -e "${_custom_color}#${Var_color_null}DBL-${_debug_level}${_custom_color}#${Var_color_null} ${_line_wrap_message}"
#		${Var_echo_exec_path} -e "${_line_wrap_message}"
	fi
	## Check if log level is high enough, then check if logging is enabled.
	if [ "${Var_logging}" = "${_log_level}" ] || [ "${_log_level}" -lt "${Var_logging}" ]; then
		## Make log directory if not present
		if ! [ -d "${Var_log_file_name##*/}" ] && ! [ -z "${Var_log_file_name##*/}" ]; then
			${Var_mkdir_exec_path} -vp "${Var_log_file_name%/*}"
		fi
		## Make log file with specific permissions and ownership if nonexistent
		if ! [ -f "${Var_log_file_name}" ] && ! [ -z "${Var_log_file_name}" ]; then
			touch "${Var_log_file_name}"
			${Var_chmod_exec_path} "${Var_log_file_permissions}" "${Var_log_file_name}"
			${Var_chown_exec_path} "${Var_log_file_ownership}" "${Var_log_file_name}"

		fi
		${Var_echo_exec_path} "#DBL-${_debug_level}# ${_message}" >> "${Var_log_file_name}"
	fi
}
## This function is called when script exits to clean up named pipe if present
##  the trap is then called prior to assigning any other functions or taking
##  any further actions.
Func_trap_cleanup(){
	_exit_status="$1"
	Func_messages "# Exit code [${_exit_status}] status detected..." '1' '2'
	if [ -p "${Var_pipe_file_name}" ]; then
		Func_messages "# ...Cleaning up [${Var_pipe_file_name}] pipe now with [eval ${Var_trap_command}] command" '1' '2'
		${Var_trap_command}
	else
		Func_messages "# ...No pipe to remove at [${Var_pipe_file_name}]" '1' '2'
	fi
	case "${Var_remove_script_log_on_exit_yn}" in
		y|Y|yes|Yes|YES)
			Func_messages "# ...Cleaning up [${Var_log_file_name}] ${Var_script_name} log file now with [rm -v ${Var_log_file_name}] command" '1' '2'
			${Var_rm_exec_path} -v "${Var_log_file_name}"
		;;
		*)
			Func_messages "# ...Please check [${Var_log_file_name}] log file if errors occurred. End of useful logging at [${Var_star_date}] seconds after 1970-01-01 00:00:00 UTC" '1' '2'
		;;
	esac
	Func_messages "# ${Var_script_name} quitting and turning bash history back on now, press [Enter] to return to terminal" '1' '2'
	set -o history
}

## Following function is called within Func_check_args function if command line options where passed to script.
## Example call for bellow function
#Func_assign_arg '' "" ''
Func_assign_arg(){
	_var_name="${1?No variable name passed to Func_assign_arg function}"
	_var_value="${2?No value passed to Func_assign_arg function}"
	_var_string_type="${3?No string filtering type passed to Func_assign_arg function}"
	case "${_var_string_type}" in
		number)
			declare -g "${_var_name}=${_var_value//${Var_number_regex}/}"
			Func_messages "# Func_assign_arg declared [${_var_name}=${_var_value//${Var_number_regex}/}]" '1' '42'
		;;
		azAZ)
			declare -g "${_var_name}=${_var_value//${Var_azAZ_regex}/}"
			Func_messages "# Func_assign_arg declared [${_var_name}=${_var_value//${Var_azAZ_regex}/}]" '1' '42'
		;;
		string)
			declare -g "${_var_name}=${_var_value//${Var_string_regex}/}"
			Func_messages "# Func_assign_arg declared [${_var_name}=${_var_value//${Var_string_regex}/}]" '1' '42'
		;;
		*)
			declare -g "${_var_name}=${_var_value//${Var_parsing_allowed_chars}/}"
			Func_messages "# Func_assign_arg declared [${_var_name}=${_var_value//${Var_parsing_allowed_chars}/}]" '1' '42'
		;;
	esac
}
## Following function is called within Func_check_args function if '-h' or '--help' was passed to script
Func_usage_options(){
	if [ "${#@}" = "0" ]; then
	#	Func_messages "# " '0' '42'
		${Var_echo_exec_path} "## Usage options recognized by [${Var_script_name}] and their current values..."
		${Var_echo_exec_path} "#  --copy-save-yn		Var_script_copy_save=\"${Var_script_copy_save}\""
		${Var_echo_exec_path} "#  --copy-save-name		Var_script_copy_name=\"${Var_script_copy_name}\""
		${Var_echo_exec_path} "#  --copy-save-permissions	Var_script_copy_permissions=\"${Var_script_copy_permissions}\""
		${Var_echo_exec_path} "#  --copy-save-ownership	Var_script_copy_ownership=\"${Var_script_copy_ownership}\""
		${Var_echo_exec_path} "#  --debug-level		Var_debugging=\"${Var_debugging}\""
		${Var_echo_exec_path} "#  --disown-yn			Var_disown_parser_yn=\"${Var_disown_parser_yn}\""
		${Var_echo_exec_path} "#  --log-level			Var_logging=\"${Var_logging}\""
		${Var_echo_exec_path} "#  --log-file-location		Var_log_file_name=\"${Var_log_file_name}\""
		${Var_echo_exec_path} "#  --log-file-permissions	Var_log_file_permissions=\"${Var_log_file_permissions}\""
		${Var_echo_exec_path} "#  --log-file-ownership		Var_log_file_ownership=\"${Var_log_file_ownership}\""
		${Var_echo_exec_path} "#  --log-auto-delete-yn		Var_remove_script_log_on_exit_yn=\"${Var_remove_script_log_on_exit_yn}\""
		${Var_echo_exec_path} "#  --named-pipe-name		Var_pipe_file_name=\"${Var_pipe_file_name}\""
		${Var_echo_exec_path} "#  --named-pipe-permissions	Var_pipe_permissions=\"${Var_pipe_permissions}\""
		${Var_echo_exec_path} "#  --named-pipe-ownership	Var_pipe_ownership=\"${Var_pipe_ownership}\""
		${Var_echo_exec_path} "#  --listener-quit-string	Var_pipe_quit_string=\"${Var_pipe_quit_string}\""
		${Var_echo_exec_path} "#  --listener-trap-command	Var_trap_command=\"${Var_trap_command}\""
		${Var_echo_exec_path} "#  --output-pre-parse-yn		Var_preprocess_for_comments_yn=\"${Var_preprocess_for_comments_yn}\""
		${Var_echo_exec_path} "#  --output-pre-parse-comment-string	Var_parsing_comment_pattern=\"${Var_parsing_comment_pattern}\""
		${Var_echo_exec_path} "#  --output-pre-parse-allowed-chars	Var_parsing_allowed_chars=\"${Var_parsing_allowed_chars}\""
		${Var_echo_exec_path} "#  --output-parse-name		Var_parsing_output_file=\"${Var_parsing_output_file}\""
		${Var_echo_exec_path} "#  --output-gpg-recipient	Var_gpg_recipient=\"${Var_gpg_recipient}\""
		${Var_echo_exec_path} "#  --output-save-yn		Var_save_encryption_yn=\"${Var_save_encryption_yn}\""
		${Var_echo_exec_path} "#  --output-rotate-yn		Var_log_rotate_yn=\"${Var_log_rotate_yn}\""
		${Var_echo_exec_path} "#  --output-rotate-max-bites	Var_log_max_size=\"${Var_log_max_size}\""
		${Var_echo_exec_path} "#  --output-rotate-check-frequency	Var_log_check_frequency=\"${Var_log_check_frequency}\""
		${Var_echo_exec_path} "#  --output-rotate-actions	Var_log_rotate_actions=\"${Var_log_rotate_actions}\""
		${Var_echo_exec_path} "#  --output-rotate-recipient	Var_log_rotate_recipient=\"${Var_log_rotate_recipient}\""
		${Var_echo_exec_path} "#  --output-parse-command	Var_parsing_command=\"${Var_parsing_command}\""
		${Var_echo_exec_path} "#  --output-bulk-dir		Var_parsing_bulk_out_dir=\"${Var_parsing_bulk_out_dir}\""
		${Var_echo_exec_path} "#  --output-bulk-suffix		Var_bulk_output_suffix=\"${Var_bulk_output_suffix}\""
		${Var_echo_exec_path} "#  --padding-enable-yn		Var_enable_padding_yn=\"${Var_enable_padding_yn}\""
		${Var_echo_exec_path} "#  --padding-length		Var_padding_length=\"${Var_padding_length}\""
		${Var_echo_exec_path} "#  --padding-placement		Var_padding_placement=\"${Var_padding_placement}\""
		${Var_echo_exec_path} "#  --source-var-file		Var_source_var_file=\"${Var_source_var_file}\""
		${Var_echo_exec_path} "#  --save-options-yn		Var_save_options=\"${Var_save_options}\""
		${Var_echo_exec_path} "#  --save-variables-yn		Var_save_variables=\"${Var_save_variables}\""
		${Var_echo_exec_path} "#  --license"
		${Var_echo_exec_path} "#  --help"
		${Var_echo_exec_path} "## Overwrite any option above with the following syntax"
		${Var_echo_exec_path} -e "${Var_color_red}#${Var_color_null}  --<option-name>=\"<new-value>\""
		${Var_echo_exec_path} "## Overwrite any variable found within this script & not found above with the following syntax"
		${Var_echo_exec_path} -e "${Var_color_red}#${Var_color_null}  ---<Var_name>=\"<Var_value>\""
		${Var_echo_exec_path} "#  Note the above '---' method does Not allow for spaces within 'Var_value' unless using sub-shell redirection; see bellow examples"
		${Var_echo_exec_path} -e "${Var_color_red}#${Var_color_null}  ---Var_name=\$(echo \"\${HOME}\")"
		${Var_echo_exec_path} -e "${Var_color_red}#${Var_color_null}  ---Var_name=\"\$(echo \${HOME})\""
		${Var_echo_exec_path} "#  However, the results still must not contain spaces; escaped or otherwise."
		${Var_echo_exec_path} "## Any unrecognized or unknown input otherwise unmatched above is then written to named pipe if/when available."
	else
		_help_lookup=( "${@}" )
		let _help_count=0
		until [ "${_help_count}" = "${#_help_lookup[@]}" ] ; do
			echo "# Checking if ${Var_script_name} has help on [${_help_lookup[${_help_count}]}]"
			if [ -e "$(which ${_help_lookup[${_help_count}]})" ] && ! [ "${_help_lookup[${_help_count}]}" = "${Var_script_name}" ] && ! [ "${_help_lookup[${_help_count}]}" = "${Var_script_dir}/${Var_script_name}" ]; then
				${Var_echo_exec_path} -e "${Var_color_red}#${Var_color_null} ${Var_script_name} found [$(which ${_help_lookup[${_help_count}]})]"
				${Var_echo_exec_path} "# This is external to ${Var_script_name} but maybe displayed upon user [${Var_script_current_user}] request."
				Func_prompt_continue "Func_usage_options"
				if test "$(which ${_help_lookup[${_help_count}]}) --help"; then
					$(which ${_help_lookup[${_help_count}]}) --help
				elif test "help ${_help_lookup[${_help_count}]}"; then
					help ${_help_lookup[${_help_count}]}
				fi
			else
				case "${_help_lookup[${_help_count}]}" in
# TO-DO : Write help using bellow template for command line options.
					#)
					#	${Var_echo_exec_path} -e "${Var_color_lpurple}#${Var_color_null} ${Var_script_name} recognized internal help for [${_help_lookup[${_help_count}]}]"
					#	${Var_echo_exec_path} '#'
					#;;
					*)
						${Var_echo_exec_path} -e "${Var_color_red}#${Var_color_null} ${Var_script_name} not find ${_help_lookup[${_help_count}]}"
					;;
				esac
			fi
			let _help_count++
		done
	fi
}
## If unrecognized input was passed to script then push it through named pipe
##  only if the pipe file exists too. Else message user that extra input read
##  was unrecognized. This function is called within this scripts main function.
Func_write_unrecognized_input_to_pipe(){
	if [ "${#Var_extra_input[@]}" -gt '0' ] && [ -p "${Var_pipe_file_name}" ]; then
		Func_messages "${Var_script_name} detected extra (unrecognized as an argument) input" '1' '2'
		Func_messages "# \${Var_extra_input[@]}  will now be written to [${Var_pipe_file_name}] for parsing" '1' '2'
		${Var_cat_exec_path} <<<"${Var_extra_input[@]}" > "${Var_pipe_file_name}"
	else
		Func_messages "${Var_script_name} did note detected extra (unrecognized as an argument) input" '1' '2'
	fi
}
## Check if script was passed any recognized arguments
##  that may overwrite default variable values
Func_check_args(){
	_input_array=( "${@}" )
	let _arg_count=0
	until [ "${_arg_count}" = "${#_input_array[@]}" ]; do
		_arg="${_input_array[${_arg_count}]}"
		case "${_arg%=*}" in
			--copy-save-yn)
				Func_assign_arg 'Var_script_copy_save' "${_arg#*=}" 'azAZ'
			;;
			--copy-save-name)
				Func_assign_arg 'Var_script_copy_name' "${_arg#*=}" 'string'
			;;
			--copy-save-permissions)
				Func_assign_arg 'Var_script_copy_permissions' "${_arg#*=}" 'number'
			;;
			--copy-save-ownership)
				Func_assign_arg 'Var_script_copy_ownership' "${_arg#*=}" 'string'
			;;
			--debug-level)
				Func_assign_arg 'Var_debugging' "${_arg#*=}" 'number'
			;;
			--disown-yn)
				Func_assign_arg 'Var_disown_parser_yn' "${_arg#*=}" 'azAZ'
			;;
			--log-level)
				Func_assign_arg 'Var_logging' "${_arg#*=}" 'number'
			;;
			--log-file-location)
				Func_assign_arg 'Var_log_file_name' "${_arg#*=}" 'string'
			;;
			--log-file-permissions)
				Func_assign_arg 'Var_log_file_permissions' "${_arg#*=}" 'number'
			;;
			--log-file-ownership)
				Func_assign_arg 'Var_log_file_ownership' "${_arg#*=}" 'string'
			;;
			--log-auto-delete-yn)
				Func_assign_arg 'Var_remove_script_log_on_exit_yn' "${_arg#*=}" 'azAZ'
			;;
			--named-pipe-name)
				Func_assign_arg 'Var_pipe_file_name' "${_arg#*=}" 'string'
				Func_assign_arg 'Var_trap_command' "${Var_rm_exec_path} -f ${Var_pipe_file_name}" 'null'
			;;
			--named-pipe-permissions)
				Func_assign_arg 'Var_pipe_permissions' "${_arg#*=}" 'number'
			;;
			--named-pipe-ownership)
				Func_assign_arg 'Var_pipe_ownership' "${_arg#*=}" 'string'
			;;
			--listener-quit-string)
				Func_assign_arg 'Var_pipe_quit_string' "${_arg#*=}" 'string'
			;;
			--listener-trap-command)
				Func_assign_arg 'Var_trap_command' "${_arg#*=}" 'null'
			;;
			--output-pre-parse-yn)
				Func_assign_arg 'Var_preprocess_for_comments_yn' "${_arg#*=}" 'azAZ'
			;;
			--output-pre-parse-comment-string)
				Func_assign_arg 'Var_parsing_comment_pattern' "${_arg#*=}" 'null'
			;;
			--output-pre-parse-allowed-chars)
				Func_assign_arg 'Var_parsing_allowed_chars' "${_arg#*=}" 'null'
			;;
			--output-parse-name)
				Func_assign_arg 'Var_parsing_output_file' "${_arg#*=}" 'string'
			;;
			--output-gpg-recipient)
				Func_assign_arg 'Var_gpg_recipient' "${_arg#*=}" 'string'
				Func_assign_arg 'Var_gpg_recipient_options' "--always-trust --armor --batch --recipient ${Var_gpg_recipient} --encrypt" 'null'
				Func_assign_arg 'Var_parsing_command' "${Var_gpg_exec_path} ${Var_gpg_recipient_options}" 'null'
			;;
			--output-save-yn)
				Func_assign_arg 'Var_save_encryption_yn' "${_arg#*=}" 'azAZ'
			;;
			--output-rotate-yn)
				Func_assign_arg 'Var_log_rotate_yn' "${_arg#*=}" 'azAZ'
			;;
			--output-rotate-max-bites)
				Func_assign_arg 'Var_log_max_size' "${_arg#*=}" 'number'
			;;
			--output-rotate-check-frequency)
				Func_assign_arg 'Var_log_check_frequency' "${_arg#*=}" 'number'
			;;
			--output-rotate-actions)
				Func_assign_arg 'Var_log_rotate_actions' "${_arg#*=}" 'string'
			;;
			--output-rotate-recipient)
				Func_assign_arg 'Var_log_rotate_recipient' "${_arg#*=}" 'string'
			;;
			--output-parse-command)
				Func_assign_arg 'Var_parsing_command' "${_arg#*=}" 'null'
			;;
			--output-bulk-dir)
				Func_assign_arg 'Var_parsing_bulk_out_dir' "${_arg#*=}" 'string'
			;;
			--output-bulk-suffix)
				Func_assign_arg 'Var_bulk_output_suffix' "${_arg#*=}" 'string'
			;;
			--padding-enable-yn)
				Func_assign_arg 'Var_enable_padding_yn' "${_arg#*=}" 'string'
			;;
			--padding-length)
				Func_assign_arg 'Var_padding_length' "${_arg#*=}" 'string'
			;;
			--padding-placement)
				Func_assign_arg 'Var_padding_placement' "${_arg#*=}" 'string'
			;;
			--save-options-yn)
				Func_assign_arg 'Var_save_options' "${_arg#*=}" 'string'
			;;
			--save-variables-yn)
				Func_assign_arg 'Var_save_variables' "${_arg#*=}" 'string'
			;;
			--source-var-file)
				Func_assign_arg 'Var_source_var_file' "${_arg#*=}" 'string'
				## Check if sourcing file passed is a file else value will be used
				##  with above options for saving variables or options to the values path
				if [ -f "${Var_source_var_file}" ]; then
					source "${Var_source_var_file}"
				fi
			;;
			---*)
				Var_extra_var_var="${_arg%=*}"
				Var_extra_var_value="${_arg#*=}"
				${Var_echo_exec_path} -e "${Var_color_lpurple}#${Var_color_null} Custom variable: ${Var_extra_var_var/---/}"
				${Var_echo_exec_path} -e "${Var_color_lpurple}#${Var_color_null} Custom value: ${Var_extra_var_value}"
				Func_assign_arg "${Var_extra_var_var/---/}" "${Var_extra_var_value}" 'string'
			;;
			--help|-h)
				Var_help_var="${_arg%=*}"
				Var_help_value="${_arg#*=}"
				if ! [ -z "${#Var_help_value}" ] && ! [ "${Var_help_var}" = "${Var_help_value}" ]; then
					Func_usage_options "${Var_help_value}"
					unset Var_help_var
					unset Var_help_value
				else
					Func_usage_options
				fi
				exit 0
			;;
			--license)
				Func_script_license_customizer
				exit 0
			;;
			*)
				${Var_echo_exec_path} -e "${Var_color_lred}# Unknown input read by ${Var_script_name}\n#\t Try the following for help${Var_color_null}\n${Var_color_lred}#${Var_color_null}\t${Var_script_dir}/${Var_script_name} --help"
				${Var_echo_exec_path} -e "${Var_color_red}#${Var_color_null} This unknown input will be written to named pipe when available."
				${Var_echo_exec_path} -e "${Var_color_red}#${Var_color_null} Current count of unknown input [${#Var_extra_input[@]}]"
				declare -ga "Var_extra_input+=( ${_arg} )"
			;;
		esac
		let _arg_count++
	done
	unset _arg_count
}
## Check if gpg parser and/or log rotate recipients are set to non defaults.
##  Else prompt user for these values
Func_check_recipients(){
	if [ -z "${#Var_gpg_recipient}" ] || [[ "${Var_gpg_recipient}" == "user@host.domain" ]]; then
		Func_messages "# Warning - [\${Var_gpg_recipient}=${Var_gpg_recipient}] is improper, set with '--output-parse-recipient' option at runtime of ${Var_script_name} or input a value when prompted bellow" '1' '2'
		read -pr 'Please input your pub-key email address: ' _response
		if ! [ -z "${#_response}" ]; then
			Func_assign_arg 'Var_gpg_recipient' "${_response}" 'string'
			Func_assign_arg 'Var_gpg_recipient_options' "--always-trust --armor --batch --recipient ${Var_gpg_recipient} --encrypt" 'null'
			Func_assign_arg 'Var_parsing_command' "${Var_gpg_exec_path} ${Var_gpg_recipient_options}" 'null'
		else
			Func_messages "# Error - [\${Var_gpg_recipient}] unset, quiting now" '0' '1'
			exit 1
		fi
	fi
	## Only check for second email address if log rotation options are
	##  enabled, otherwise unused
	case "${Var_log_rotate_yn}" in
		Y|y|Yes|yes|YES)
			if [ -z "${#Var_log_rotate_recipient}" ] || [[ "${Var_log_rotate_recipient}" == "user@host.domain" ]]; then
				Func_messages "# Warning - [\${Var_log_rotate_recipient}=${Var_log_rotate_recipient}] is improper, set with '--output-rotate-recipient' option at runtime of ${Var_script_name} or input a value when prompted bellow" '1' '2'
				read -pr 'Please input your pub-key email address: ' _response
				if ! [ -z "${#_response}" ]; then
					Func_assign_arg 'Var_gpg_recipient' "${_response}" 'string'
				else
					Func_messages "# Error - [\${Var_log_rotate_recipient}] unset, quiting now" '0' '1'
					exit 1
				fi
			fi
		;;
	esac
}

## Check disown settings prior to setting further functions. Sets trap on exit now
##  or hold trapping set actions till we are inside while loop.
case "${Var_disown_parser_yn}" in
	Y|y|Yes|yes|YES)
		${Var_echo_exec_path} "# ${Var_script_name} will differ trapping until just before reading loop"
	;;
	*)
		${Var_echo_exec_path} "# ${Var_script_name} will set exit trap now."
		trap 'Func_trap_cleanup $?' EXIT
	;;
esac

## This function is used near the beginning of scripted run time if the debug level is
##  high enough to warrant pausing for user interaction. Debug level [3] or greater enables
##  anything lower and the script will continue until errors or quit signals are received.
Func_prompt_continue(){
	_calling_function="${1:-unassigned}"
	Func_messages "# ${_calling_function} would like to know if you wish to continue." '0'
	${Var_echo_exec_path} -n '# Type [Y] and enter to continue or anything else to quit now : '
	read -r _user_input
	case "${_user_input}" in
		y|Y|yes|Yes|YES)
			Func_messages "# ${Var_script_name} read [${_user_input}] and will continue now..." '0' '1'
		;;
		*)
			Func_messages "# ${Var_script_name} read [${_user_input}] and will quit now..." '0' '1'
			exit 1
		;;
	esac
}

## Print this script's usage license agreement info
Func_script_license_customizer(){
	Func_messages "# " '0' '42'
	Func_messages "## Salutations ${Var_script_current_user:-${USER}}, the following license" '0' '42'
	Func_messages "#  only applies to this script [${Var_script_title}] and the customized" '0' '42'
	Func_messages '#  scripts that this script writes. Software external to but used by' '0' '42'
	Func_messages "#  [${Var_script_name}] and the customized scripts it writes are" '0' '42'
	Func_messages '#  protected under their own licensing usage agreements. The' '0' '42'
	Func_messages '#  authors of this project assume **no** rights to modify software' '0' '42'
	Func_messages "#  licensing agreements external to [${Var_script_name}] or the custom" '0' '42'
	Func_messages '#  scripts that it writes' '0' '42'
	Func_messages '## GNU AGPL v3 Notice start' '0' '42'
	Func_messages "# ${Var_script_name}, maker of named pipe parsing template Bash scripts." '0' '42'
	Func_messages "#  Copyright (C) 2016 S0AndS0" '0' '42'
	Func_messages '# This program is free software: you can redistribute it and/or modify' '0' '42'
	Func_messages '#  it under the terms of the GNU Affero General Public License as' '0' '42'
	Func_messages '#  published by the Free Software Foundation, version 3 of the' '0' '42'
	Func_messages '#  License.' '0' '42'
	Func_messages '# You should have received a copy of the GNU Afferno General Public License' '0' '42'
	Func_messages '# along with this program. If not, see <http://www.gnu.org/licenses/>.' '0' '42'
	Func_messages "#  Contact authors of [${Var_script_name}] at: ${Var_authors_contact}" '0' '42'
	Func_messages '# GNU AGPL v3 Notice end' '0' '42'
	if [ -r "${Var_script_dir}/Licenses/GNU_AGPLv3_${Var_script_name%.*}.md" ]; then
		Func_messages '## Found local license file, prompting to display...' '0' '42'
		Func_prompt_continue "Func_script_license_customizer"
		less -R5 "${Var_script_dir}/Licenses/GNU_AGPLv3_${Var_script_name%.*}.md"
	fi
}

## Print info about variables assigned and if debug level is high enough prompt the
##  user to continue prior to allowing further functions to process, ie call the above
##  function after printing variable info.
Func_variable_assignment_reader(){
	## Start: Template of adding messages to read out current settings
	#	Func_messages '##  ##' '2' '3'
	#	
	#	Func_messages '#  [${}]' '2' '3'
	#	Func_messages "#  ${}" '2' '3'
	#	
	## End: Template of adding messages to read out current settings
	## Print and/or log variables that are not editable by user input first.
	Func_messages '## File path variables to file system executables used by this script ##' '2' '3'
	Func_messages "# Parsing executable file path: [${Var_gpg_exec_path}]" '2' "3"
	Func_messages "# Change permissions (chmod) executable file path: [${Var_chmod_exec_path}]" '2' '3'
	Func_messages "# Change Ownership (chown) executable file path: [${Var_chown_exec_path}]" '2' '3'
	Func_messages "# Echo (echo) executable file path: [${Var_echo_exec_path}]" '2' '3'
	Func_messages "# Make First in First out named pipe (mkfifo) executable file path: [${Var_mkfifo_exec_path}]" '2' '3'
	Func_messages "# Concatenate (cat) executable file path: [${Var_cat_exec_path}]" '2' '3'
	Func_messages "# Make directory (mkdir) executable file path: [${Var_mkdir_exec_path}]" '2' '3'
	Func_messages "# Move directory or file (mv) executable file path: [${Var_mv_exec_path}]" '2' '3'
	Func_messages "# Remove directory or file (rm) executable file path: [${Var_rm_exec_path}]" '2' '3'
	Func_messages '## Bash shell built in variables used by this script ##' '2' '3'
	Func_messages "# Script directory: [${Var_script_dir}]" '2' "3"
	Func_messages "# Script name: [${Var_script_name}]" '2' "3"
	Func_messages "# Function PID: [${Var_subshell_pid}]" '2' '3'
	Func_messages "# PID of this script: [${Var_script_pid}]" '2' '3'
	Func_messages "# User executing this script: [${Var_script_current_user}]" '2' '3'
	## If user input was provided then print and/or log user editable variables,
	##  else print and/or log script assigned variables.
	if [ "${#_user_input}" -gt "0" ]; then
		Func_messages '## User modifiable variables from command line maybe displayed with ##' '2' '3'
		Func_messages "# ${Var_script_dir}/${Var_script_name} --help" '2' '3'
		### Recognized commands can be printed with "${Var_script_name} --help"
	else
		Func_messages '## Logging & settings internal to this script ##' '2' '3'
		Func_messages "# Script debugging level: [${Var_debugging}]" '2' "3"
		Func_messages "# Save parsed input to file: [${Var_save_encryption_yn}" '2' "3"
		Func_messages "# Encrypt lines and files sent to named pipe to recipient: [${Var_gpg_recipient}]" '2' "3"
		Func_messages "# GPG options to use: [${Var_gpg_recipient_options}]" '2' "3"
		Func_messages "# Named pipe file path: [${Var_pipe_file_name}]" '2' "3"
		Func_messages "# File path and name to save logs (parsed from named pipe) to: [${Var_parsing_output_file}]" '2' "3"
		Func_messages '## Script &/or template shared settings ##' '2' '3'
		Func_messages "# Script quit listening string: ${Var_pipe_quit_string}" '2' "3"
		Func_messages "# Named pipe permissions: [${Var_pipe_permissions}]" '2' "3"
		Func_messages "# Named pipe ownership: [${Var_pipe_ownership}]" '2' "3"
		Func_messages "# Command to run on exit: [${Var_trap_command}]" '2' "3"
		Func_messages "# Command to use when parsing input from named pipe: [${Var_parsing_command}]" '2' "3"
		Func_messages "# Enable or disable log rotation: [${Var_log_rotate_yn}]" '2' '3'
		Func_messages "# Log file maximum variable: [${Var_log_max_size}]" '2' '3'
		Func_messages "# Log file check frequency: [${Var_log_check_frequency}]" '2' '3'
		Func_messages "# Log rotation actions: [${Var_log_rotate_actions}]" '2' '3'
		Func_messages "# Log rotation file recipient: [${Var_log_rotate_recipient}]" '2' '3'
		Func_messages '## Template save script variables ##' '2' '3'
		Func_messages "# Save copy path: [${Var_script_copy_name}]" '2' '3'
		Func_messages "# Script copy permissions: [${Var_script_copy_permissions}]" '2' '3'
		Func_messages "# Script copy owner ship: [${Var_script_copy_ownership}]" '2' '3'
		Func_messages '## Read input specific parsing settings ##' '2' '3'
		Func_messages "# Check for pre commented input before parsing: [${Var_preprocess_for_comments_yn}]" '2' '3'
		Func_messages "# Recognized comments: [${Var_parsing_comment_pattern}]" '2' '3'
		Func_messages "# Allowed characters without preceding comment: [${Var_parsing_allowed_chars}]" '2' '3'
		Func_messages "# Bulk suffix for parsed input: [${Var_bulk_output_suffix}]" '2' '3'
		Func_messages '## Padding output values  ##' '2' '3'
		Func_messages "# Enable or disable padding: [${Var_enable_padding_yn}]" '2' '3'
		Func_messages "# Padding length: [${Var_padding_length}]" '2' '3'
		Func_messages "# Padding placement: [${Var_padding_placement}]" '2' '3'
		Func_messages "# Padding example one: [${Var_padding_command}]" '2' '3'
		Func_messages "# Padding example two: $(base64 /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c32)" '2' '3'
	fi
	## If debugging is equal to or grater than '3' then print prompt
	##  to continue, otherwise let further processing to continue.
	if [ "${Var_debugging}" = "3" ] || [ "${Var_debugging}" -gt "3" ]; then
		Func_prompt_continue "Func_variable_assignment_reader"
	fi
}
	
## The following two functions are called only if Func_main function detects that it should
##  save either a variable or option file for latter use with this script.
Func_save_options(){
	if ! [ -f "${Var_source_var_file}" ]; then
		cat > "${Var_source_var_file}" <<EOF
#!/usr/bin/env bash
if [ -e "${Var_script_dir}/${Var_script_name}" ]; then
	echo "# Running ${Var_script_dir}/${Var_script_name} with options from [${Var_source_var_file}]"
	${Var_script_dir}/${Var_script_name} --copy-save-yn="${Var_script_copy_save}"\\
	 --copy-save-name="${Var_script_copy_name}"\\
	 --copy-save-permissions="${Var_script_copy_permissions}"\\
	 --copy-save-ownership="${Var_script_copy_ownership}"\\
	 --debug-level="${Var_debugging}"\\
	 --disown-yn="${Var_disown_parser_yn}"\\
	 --log-level="${Var_logging}"\\
	 --log-file-location="${Var_log_file_name}"\\
	 --log-file-permissions="${Var_log_file_permissions}"\\
	 --log-file-ownership="${Var_log_file_ownership}"\\
	 --log-auto-delete-yn="${Var_remove_script_log_on_exit_yn}"\\
	 --named-pipe-name="${Var_pipe_file_name}"\\
	 --named-pipe-permissions="${Var_pipe_permissions}"\\
	 --named-pipe-ownership="${Var_pipe_ownership}"\\
	 --listener-quit-string="${Var_pipe_quit_string}"\\
	 --output-pre-parse-yn="${Var_preprocess_for_comments_yn}"\\
	 --output-pre-parse-comment-string="${Var_parsing_comment_pattern}"\\
	 --output-pre-parse-allowed-chars="${Var_parsing_allowed_chars}"\\
	 --output-parse-name="${Var_parsing_output_file}"\\
	 --output-gpg-recipient="${Var_gpg_recipient}"\\
	 --output-save-yn="${Var_save_encryption_yn}"\\
	 --output-rotate-yn="${Var_log_rotate_yn}"\\
	 --output-rotate-max-bites="${Var_log_max_size}"\\
	 --output-rotate-check-frequency="${Var_log_check_frequency}"\\
	 --output-rotate-actions="${Var_log_rotate_actions}"\\
	 --output-rotate-recipient="${Var_log_rotate_recipient}"\\
	 --output-bulk-dir="${Var_parsing_bulk_out_dir}"\\
	 --output-bulk-suffix="${Var_bulk_output_suffix}"\\
	 --padding-enable-yn="${Var_enable_padding_yn}"\\
	 --padding-length="${Var_padding_length}"\\
	 --padding-placement="${Var_padding_placement}"
else
	echo "# Error finding executable permissions for: ${Var_script_dir}/${Var_script_name}"
fi
EOF
	fi
	
}
Func_save_variables(){
	if ! [ -f "${Var_source_var_file}" ]; then
		cat > "${Var_source_var_file}" <<EOF
### This is a configuration file written by and licensed under
##  the same licensing and usage agreement referenced in the
##  following script file path.
##  Saved by: ${Var_script_name}
##   at: $(date)

### Following variables can be controlled via command line options
##  passed to the above script name or variables  maybe loaded
##  into the above script via the following CLO
##   --source-var-file="${Var_source_var_file}"
##  each of the following will be pre-seeded by it's
##  related command line option and is only included
##  to aid users in understanding options available
##  and not to encourage one method of use over an other.
Var_script_copy_save="${Var_script_copy_save}"
## --copy-save-name="${Var_script_copy_name}"
Var_script_copy_name="${Var_script_copy_name}"
## --copy-save-permissions="${Var_script_copy_permissions}"
Var_script_copy_permissions="${Var_script_copy_permissions}"
## --copy-save-ownership="${Var_script_copy_ownership}"
Var_script_copy_ownership="${Var_script_copy_ownership}"
## --debug-level="${Var_debugging}"
Var_debugging="${Var_debugging}"
## --disown-yn="${Var_disown_parser_yn}"
Var_disown_parser_yn="${Var_disown_parser_yn}"
## --log-level="${Var_logging}"
Var_logging="${Var_logging}"
## --log-file-location="${Var_log_file_name}"
Var_log_file_name="${Var_log_file_name}"
## --log-file-permissions="${Var_log_file_permissions}"
Var_log_file_permissions="${Var_log_file_permissions}"
## --log-file-ownership="${Var_log_file_ownership}"
Var_log_file_ownership="${Var_log_file_ownership}"
## --log-auto-delete-yn="${Var_remove_script_log_on_exit_yn}"
Var_remove_script_log_on_exit_yn="${Var_remove_script_log_on_exit_yn}"
## --named-pipe-name="${Var_pipe_file_name}"
Var_pipe_file_name="${Var_pipe_file_name}"
## --named-pipe-permissions="${Var_pipe_permissions}"
Var_pipe_permissions="${Var_pipe_permissions}"
## --named-pipe-ownership="${Var_pipe_ownership}"
Var_pipe_ownership="${Var_pipe_ownership}"
## --listener-quit-string="${Var_pipe_quit_string}"
Var_pipe_quit_string="${Var_pipe_quit_string}"
## --output-pre-parse-yn="${Var_preprocess_for_comments_yn}"
Var_preprocess_for_comments_yn="${Var_preprocess_for_comments_yn}"
## --output-pre-parse-comment-string="${Var_parsing_comment_pattern}"
Var_parsing_comment_pattern="${Var_parsing_comment_pattern}"
## --output-pre-parse-allowed-chars="${Var_parsing_allowed_chars}"
Var_parsing_allowed_chars="${Var_parsing_allowed_chars}"
## --output-parse-name="${Var_parsing_output_file}"
Var_parsing_output_file="${Var_parsing_output_file}"
## --output-gpg-recipient="${Var_gpg_recipient}"
Var_gpg_recipient="${Var_gpg_recipient}"
## --output-save-yn="${Var_save_encryption_yn}"
Var_save_encryption_yn="${Var_save_encryption_yn}"
## --output-rotate-yn="${Var_log_rotate_yn}"
Var_log_rotate_yn="${Var_log_rotate_yn}"
## --output-rotate-max-bites="${Var_log_max_size}"
Var_log_max_size="${Var_log_max_size}"
## --output-rotate-check-frequency="${Var_log_check_frequency}"
Var_log_check_frequency="${Var_log_check_frequency}"
## --output-rotate-actions="${Var_log_rotate_actions}"
Var_log_rotate_actions="${Var_log_rotate_actions}"
## --output-rotate-recipient="${Var_log_rotate_recipient}"
Var_log_rotate_recipient="${Var_log_rotate_recipient}"
## --output-bulk-dir="${Var_parsing_bulk_out_dir}"
Var_parsing_bulk_out_dir="${Var_parsing_bulk_out_dir}"
## --output-bulk-suffix="${Var_bulk_output_suffix}"
Var_bulk_output_suffix="${Var_bulk_output_suffix}"
## --padding-enable-yn="${Var_enable_padding_yn}"
Var_enable_padding_yn="${Var_enable_padding_yn}"
## --padding-length="${Var_padding_length}"
Var_padding_length="${Var_padding_length}"
## --padding-placement="${Var_padding_placement}"
Var_padding_placement="${Var_padding_placement}"

## --source-var-file="${Var_source_var_file}"
#Var_source_var_file="${Var_source_var_file}"
## --save-options-yn="${Var_save_options}"
#Var_save_options="${Var_save_options}"
## --save-variables-yn="${Var_save_variables}"
#Var_save_variables="${Var_save_variables}"


### Following variables are not settable via
##  command line options and are included to
##  allow users finer grain customization of
##  script actions or behavior without need
##  of touching the main script's source

#Var_script_dir="\${0%/*}"
#Var_script_name="\${0##*/}"
#Var_script_pid="\$\$"
#Var_script_pid=\${Var_script_pid:-\$BASHPID}
# : \${USER?}
# : \${HOME?}
#Var_script_current_user="\${USER}"
Var_trap_command="${Var_rm_exec_path} -f ${Var_pipe_file_name}"

Var_chmod_exec_path="\$(which chmod)"
Var_chown_exec_path="\$(which chown)"
Var_echo_exec_path="\$(which echo)"
Var_mkfifo_exec_path="\$(which mkfifo)"
Var_cat_exec_path="\$(which cat)"
Var_mkdir_exec_path="\$(which mkdir)"
Var_mv_exec_path="\$(which mv)"
Var_rm_exec_path="\$(which rm)"
Var_tar_exec_path="\$(which tar)"
Var_gpg_exec_path="\$(which gpg2)"
Var_dev_null='/dev/null'
Var_star_date=\$(date +%s)
Var_number_regex='[^0-9]'
Var_azAZ_regex='[^a-zA-Z]'
Var_string_regex='[^a-zA-Z0-9_@,.:~\/]'
Var_color_red='\033[0:31m'
Var_color_lred='\033[1:31m'
Var_color_lpurple='\033[1:35m'
Var_color_null='\033[0m'
Var_gpg_recipient_options="--always-trust --armor --batch --recipient ${Var_gpg_recipient} --encrypt"
Var_parsing_command="${Var_gpg_exec_path} ${Var_gpg_recipient_options}"

EOF
	fi
	
}

## Function for making a named pipe if not already present and setting permissions
##  on the named pipe such that only authorized users and groups may write and read
##  to and from it. Exiting on any errors is to prevent "while" loop from initializing
##  on nonexistent pipe, ie if we can not make a pipe then do not allow reader
##  function calls from starting.
Func_mkfifo(){
	if ! [ -p "${Var_pipe_file_name}" ]; then
		Func_messages "# $(which mkfifo) \"${Var_pipe_file_name}\"" '4' '5'
		${Var_mkfifo_exec_path} "${Var_pipe_file_name}" || exit 1
	fi
	Func_messages "# ${Var_chmod_exec_path} \"${Var_pipe_permissions}\" \"${Var_pipe_file_name}\"" '4' '5'
	Func_messages "# ${Var_chown_exec_path} \"${Var_pipe_ownership}\" \"${Var_pipe_file_name}\"" '4' '5'
	${Var_chmod_exec_path} "${Var_pipe_permissions}" "${Var_pipe_file_name}" || exit 1
	${Var_chown_exec_path} "${Var_pipe_ownership}" "${Var_pipe_file_name}" || exit 1
}
## This is only called when a sufficient number of lines have been parsed, upon call
##  this function will check the log file size and rotate with time stamp if necessary.
Func_rotate_log(){
	_parsing_output_file="${1:-$Var_parsing_output_file}"
	_log_rotate_yn="${2:-$Var_log_rotate_yn}"
	_log_max_size="${3:-$Var_log_max_size}"
	_log_rotate_actions="${4:-$Var_log_rotate_actions}"
	_log_rotate_recipient="${5:-$Var_log_rotate_recipient}"
	## Reacts only to "yes" like statements for enabling log rotation actions, otherwise
	##  this whole function will be skipped and pipe read/write operations will not be blocked.
	case "${_log_rotate_yn}" in
		y|Y|yes|Yes|YES)
			if [ -f "${_parsing_output_file}" ]; then
				_file_size=$(du --bytes "${_parsing_output_file}" | awk '{print $1}' | head -n1)
				if [ "${_file_size}" -gt "${_log_max_size}" ]; then
					## Modify the '_now' variable for different time stamp formatting
					##  ie replacing '+%s' with '+%d_%m_%Y' will result in human readable
					##  time stamps instead of using seconds for time stamp
					_now=${Var_star_date}
					## Save a snap shot of above variable to bellow variable.
					##  this allows multiple log rotate actions to be preformed without
					##  having the time stamp change any between actions on the same rotation.
					##  Note the more actions you have enabled the longer that your
					##  pipe reading loop will be blocked from parsing input, this is because
					##  this functions calls are embedded in the parsing loop that checks
					##  if internal '${_count}' is greater than '${Var_log_check_frequency}'
					##  prior to allowing this function to check the log file size... a bit
					##  convoluted so check the template writer function to see this all
					##  in a much slimmer form factor.
					_timestamp="${_now}"
					## Split commas into spaces and use case to match action options
					for _actions in ${_log_rotate_actions//,/ }; do
						case "${_actions}" in
							mv|move)
								Func_messages "# Moving [${_parsing_output_file}] file to [${_parsing_output_file}.${_timestamp}]" '3' '4'
								${Var_mv_exec_path} "${_parsing_output_file}" "${_parsing_output_file}.${_timestamp}"
							;;
							compress-encrypt|encrypt)
								Func_messages "# Compressing [${_parsing_output_file}] file to [${_log_rotate_recipient}] recipient with output [${_parsing_output_file}.${_timestamp}.tar.gz.gpg] file" '3' '4'
								${Var_tar_exec_path} -cz "${_parsing_output_file}" | gpg --encrypt --recipient "${_log_rotate_recipient}" --output "${_parsing_output_file}.${_timestamp}.tar.gz.gpg"
							;;
							encrypted-email)
								Func_messages "# Sending compressed email attachment [${_parsing_output_file}.${_timestamp}.tar.gz.gpg] file to [${_log_rotate_recipient}] recipient" '3' '4'
								${Var_tar_exec_path} -cz "${_parsing_output_file}" | gpg --encrypt --recipient "${_log_rotate_recipient}" --output "${_parsing_output_file}.${_timestamp}.tar.gz.gpg"
								echo "Sent at ${_timestamp}" | mutt -s "${_parsing_output_file}.${_timestamp}.tar.gz.gpg" -a "${_parsing_output_file}.${_timestamp}.tar.gz.gpg" "${_log_rotate_recipient}"
							;;
							compressed-email)
								Func_messages "# Sending compressed email attachment [${_parsing_output_file}.${_timestamp}.tar.gz.gpg] file to [${_log_rotate_recipient}] recipient" '3' '4'
								${Var_tar_exec_path} -cz "${_parsing_output_file}" "${_parsing_output_file}.${_timestamp}.tar.gz"
								echo "Sent at ${_timestamp}" | mutt -s "${_parsing_output_file}.${_timestamp}.tar.gz" -a "${_parsing_output_file}.${_timestamp}.tar.gz" "${_log_rotate_recipient}"
							;;
							compress)
								Func_messages "# Compressing [${_parsing_output_file}] file to output [${_parsing_output_file}.${_timestamp}.tar.gz.gpg] file" '3' '4'
								${Var_tar_exec_path} -cz "${_parsing_output_file}" "${_parsing_output_file}.${_timestamp}.tar.gz"
							;;
							remove|rm|remove-old)
								Func_messages "# Removing old [${_parsing_output_file}] file and remaking new blank one with [${Var_log_file_permissions}] permissions and [${Var_log_file_ownership}] (user:group) ownership" '3' '4'
								${Var_rm_exec_path} -f "${_parsing_output_file}"
								touch "${_parsing_output_file}"
								${Var_chmod_exec_path} "${Var_log_file_permissions}" "${_parsing_output_file}"
								${Var_chown_exec_path} "${Var_log_file_ownership}" "${_parsing_output_file}"
							;;
						esac
					done
				fi
			fi
		;;
	esac
}
Map_read_array_to_output(){
	_file_to_map="$1"
	## Make an array from input, note '-t' will "trim" last new-line but otherwise not modify read lines.
	mapfile -t _lines < "${_file_to_map}"
	let _count=0
	until [[ "${Var_pipe_quit_string}" == "${_lines[${_count}]}" ]] || [ "${_count}" = "${#_lines[@]}" ]; do
		## Here is where the read input is expanded, line by line, the calling function then may make use
		##  of entire data block; based on user set preferences is how each line read is formatted.
		##  This first case branch checks for 'yes' like statements in ${Var_enable_padding} variable,
		##  skip to bellow '*)' to find out what happens when this is disabled, because when enabled
		##  this script will manipulate the lines being output quite a bit based upon enabled ${Var_padding_placement}
		##  options chosen. Warning: disable this setting for the quickest and stablest results,
		##  ie Var_enable_padding='no' is the best default
		case "${Var_enable_padding_yn}" in
			y|Y|yes|Yes|YES)
				_line=( "${_lines[${_count}]}" )
				case "${Var_padding_length}" in
					adaptive)
						_padding_length="${#_lines[${_count}]}"
					;;
					*)
						_padding_length="${Var_padding_length}"
					;;
				esac
				for _option in ${Var_padding_placement//,/ }; do
					case "${_option}" in
						append)
							Var_padding_command="$(base64 /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c${_padding_length})"
							_line+=( "${Var_padding_command}" )
						;;
						prepend)
							Var_padding_command="$(base64 /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c${_padding_length})"
							_line=( "${Var_padding_command}" "${_line[@]}" )
						;;
					esac
				done
				for _option in ${Var_padding_placement//,/ }; do
					case "${_option}" in
						above)
							Var_padding_command="$(base64 /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c${_padding_length})"
							${Var_cat_exec_path} <<<"${Var_padding_command}"
						;;
					esac
				done
				case "${Var_preprocess_for_comments_yn}" in
					y|Y|yes|Yes|YES)
						case "${_lines[${_count}]}" in
							${Var_parsing_comment_pattern})
								${Var_cat_exec_path} <<<"${_line[@]//${Var_parsing_allowed_chars}/}"
							;;
							*)
								${Var_cat_exec_path} <<<"# ${_line[*]//${Var_parsing_allowed_chars}/}"
#								${Var_cat_exec_path} <<<"# ${_line[@]//${Var_parsing_allowed_chars}/}"
							;;
						esac
						let _count++
					;;
					*)
						${Var_cat_exec_path} <<<"${_line[@]}"
						let _count++
					;;
				esac
				for _option in ${Var_padding_placement//,/ }; do
					case "${_option}" in
						bellow)
							Var_padding_command="$(base64 /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c${_padding_length})"
							${Var_cat_exec_path} <<<"${Var_padding_command}"
						;;
					esac
				done
			;;
			*)
				case "${Var_preprocess_for_comments_yn}" in
					y|Y|yes|Yes|YES)
						case "${_lines[${_count}]}" in
							${Var_parsing_comment_pattern})
								${Var_cat_exec_path} <<<"${_lines[${_count}]//${Var_parsing_allowed_chars}/}"
							;;
							*)
								${Var_cat_exec_path} <<<"# ${_lines[${_count}]//${Var_parsing_allowed_chars}/}"
							;;
						esac
						let _count++
					;;
					*)
						${Var_cat_exec_path} <<<"${_lines[${_count}]}"
						let _count++
					;;
				esac
			;;
		esac
	done
}
## Note bellow function calls the above function by assigning it to a variable; tricky...but works ;-D
Func_mkpipe_reader(){
	## While there is a pipe file under "${Var_pipe_file_name}" path
	##  AND a "break" signal is undetected assign function [Map_read_array_to_output]
	##  with above file path as first argument to a variable.
	while [ -p "${Var_pipe_file_name}" ]; do
		_mapped_array=$(Map_read_array_to_output "${Var_pipe_file_name}")
		PID_Map_read_array_to_output=$!
		## If above variable is not zero characters in length OR if above variable
		##  is NOT equal to exit string, then push above variable through
		##  further checks, else signal 'brake' (false) to parent "while" loop.
		if ! [ -z "${_mapped_array}" ] && ! [[ "${Var_pipe_quit_string}" == "${_lines[${_count}]}" ]]; then
			case "${Var_save_encryption_yn}" in
				y|Y|yes|Yes)
					## Test if input is a file path otherwise push it through parsing command
					if [ -f "${_mapped_array}" ]; then
						## Check for bulk output directory to save encrypted files to, make one
						##  if nonexistent
						if ! [ -d "${Var_parsing_bulk_out_dir}" ]; then
							${Var_mkdir_exec_path} -vp "${Var_parsing_bulk_out_dir}"
						fi
						${Var_cat_exec_path} "${_mapped_array}" | ${Var_parsing_command} >> "${Var_parsing_bulk_out_dir}/${_mapped_array##*/}${Var_bulk_output_suffix}"
						_exit_status=("${PIPESTATUS[@]}")
						Func_messages "# Encryption command [${Var_cat_exec_path} \"\${_mapped_array}\" | ${Var_parsing_command} >> \"${Var_parsing_bulk_out_dir}/${_mapped_array##*/}${Var_bulk_output_suffix}\"]" '2' '3'
#						Func_messages "# Encryption command [${Var_cat_exec_path} \"${_mapped_array}\" | ${Var_parsing_command} >> \"${Var_parsing_bulk_out_dir}/${_mapped_array##*/}${Var_bulk_output_suffix}\"]" '2' '3'
						Func_messages "# Command exit statuses [${_exit_status[*]}]" '2' '3'
					elif [ -d "${_mapped_array}" ]; then
						if ! [ -d "${Var_parsing_bulk_out_dir}" ]; then
							${Var_mkdir_exec_path} -vp "${Var_parsing_bulk_out_dir}"
						fi
						${Var_tar_exec_path} zcf - "${_mapped_array}" | ${Var_parsing_command} >> "${Var_parsing_bulk_out_dir}/${Var_star_date}_${_mapped_array//\//_}.tgz${Var_bulk_output_suffix}"
						_exit_status=("${PIPESTATUS[@]}")
						Func_messages "# Encryption command [${Var_tar_exec_path} zcf - \"\${_mapped_array}\" | ${Var_parsing_command} >> \"${Var_parsing_bulk_out_dir}/\${Var_star_date}_\${_mapped_array//\//_}.tgz${Var_bulk_output_suffix}\"]" '2' '3'
#						Func_messages "# Encryption command [${Var_tar_exec_path} zcf - \"${_mapped_array}\" | ${Var_parsing_command} >> \"${Var_parsing_bulk_out_dir}/${Var_star_date}_${_mapped_array//\//_}.tgz${Var_bulk_output_suffix}\"]" '2' '3'
						Func_messages "# Command exit statuses [${_exit_status[*]}]" '2' '3'
					else
						## Note we are doing some redirection to 'cat' instead of 'echo'ing the line
						##  as well as prepending the line with '#' commenting hash mark.
						${Var_cat_exec_path} <<<"${_mapped_array}" | ${Var_parsing_command} >> "${Var_parsing_output_file}"
						_exit_status=("${PIPESTATUS[@]}")
						let _count++
						Func_messages "# Added one (1) to internal count [${_count}]" '2' '3'
						Func_messages "# Encryption command [${Var_cat_exec_path} \"\\${_mapped_array}\" | ${Var_parsing_command} >> \"${Var_parsing_output_file}\"]" '2' '3'
#						Func_messages "# Encryption command [${Var_cat_exec_path} \"${_mapped_array}\" | ${Var_parsing_command} >> \"${Var_parsing_output_file}\"]" '2' '3'
						Func_messages "# Command exit statuses [${_exit_status[*]}]" '2' '3'
						if [ "${_count}" -gt "${Var_log_check_frequency}" ] || [ "${_count}" = "${Var_log_check_frequency}" ]; then
							Func_messages "# Checking log file size now that count has reached [${_count}]" '2' '3'
							Func_rotate_log "${Var_parsing_output_file}" "${Var_log_rotate_yn}" "${Var_log_max_size}" "${Var_log_rotate_actions}" "${Var_log_rotate_recipient}"
						fi
					fi
				;;
				*)
					Func_messages "# Reading input out to terminal..." '2' '3'
					${Var_cat_exec_path} <<<"${_mapped_array}" | ${Var_parsing_command}
					_exit_status=("${PIPESTATUS[@]}")
					let _count++
					Func_messages "# Added one (1) to internal count [${_count}]" '2' '3'
					Func_messages "# Encryption command [${Var_cat_exec_path} <<<\"\${_mapped_array}\" | ${Var_parsing_command}]" '2' '3'
					Func_messages "# Command exit statuses [${_exit_status[*]}]" '2' '3'
					Func_messages "# ...finished encryption of read input" '2' '3'
				;;
			esac
		else
			break
		fi
		unset _exit_status
		Func_messages '#------# finished' '1' '2'
	done
	_exit_status=$?
	case "${Var_disown_parser_yn}" in
		Y|y|Yes|yes|YES)
			Func_messages "Function [Map_read_input_to_array] within script [${Var_script_name}] detected exit status [${_exit_status}] and will manually run trap cleanup function now." '1' '2'
			Func_trap_cleanup "${_exit_status}"
		;;
		*)
			Func_messages "${Var_script_name} trap set outside [Map_read_input_to_array] function parsing loop" '1' '2'
		;;
	esac
}
## Note the following function is designed to take variables from above and translate them into
##  a streamlined version of this script. Thus some variables are prepended with back slashes ' \ '
##  while some are not, this is intentional and you may modify at your own risk. Safest course of
##  actions is to use this scripts main variables above to write out a customized version after
##  testing and then make further modifications to the customized version after it has been written.
Func_save_copy(){
	_script_copy_path="$1"
	if ! [ -f "${_script_copy_path}" ]; then
		Func_messages "# Writing new [${_script_copy_path}] file" '2' '3'
		${Var_cat_exec_path} > "${_script_copy_path}" <<EOF
#!/usr/bin/env bash
set +o history
## Assign name of this script and file path to variables for latter use
Var_script_dir="\${0%/*}"
Var_script_name="\${0##*/}"
Var_pipe_permissions="${Var_pipe_permissions:-420}"
Var_pipe_ownership="${Var_pipe_ownership:-$USER:$USER}"
Var_pipe_file_name="\${Var_script_dir}/\${Var_script_name%.*}.pipe"
Var_pipe_quit_string="${Var_pipe_quit_string:-quit}"
Var_trap_command="${Var_trap_command/$Var_pipe_file_name/\$Var_pipe_file_name}"
Var_parsing_command="${Var_parsing_command}"
Var_parsing_output_file="\${Var_script_dir}/\${Var_script_name%.*}.gpg"
Var_parsing_bulk_out_dir="${Var_parsing_bulk_out_dir:-/tmp/\$Var_scrip_name}"
Var_log_rotate_yn="${Var_log_rotate_yn:-no}"
Var_log_max_size="${Var_log_max_size:-4096}"
Var_log_check_frequency="${Var_log_check_frequency:-100}"
Var_log_rotate_actions="${Var_log_rotate_actions:-compress-encrypt,remove-old}"
Var_log_rotate_recipient="${Var_log_rotate_recipient}"
Var_disown_parser_yn="${Var_disown_parser_yn:-yes}"
Var_preprocess_for_comments_yn="${Var_preprocess_for_comments_yn:-no}"
Var_parsing_comment_pattern="${Var_parsing_comment_pattern}"
Var_parsing_allowed_chars="${Var_parsing_allowed_chars}"
Var_bulk_output_suffix="${Var_bulk_output_suffix:-.gpg}"
Var_star_date=\$(date +%s)
Var_enable_padding_yn="${Var_enable_padding_yn:-no}"
Var_padding_length="${Var_padding_length:-32}"
Var_padding_placement="${Var_padding_placement:-bellow}"
${Var_echo_exec_path} "### ... Starting [\${Var_script_name}] at \$(date) ... ###"
Clean_up_trap(){
	_exit_code="\$1"
	${Var_echo_exec_path} "## \${Var_script_name} detected [\${_exit_code}] exit code, cleaning up before quiting..."
	if [ -p "\${Var_pipe_file_name}" ]; then
		\${Var_trap_command}
	fi
	${Var_echo_exec_path} -n "### ... Finished [\${Var_script_name}] at \$(date) press [Enter] to resume terminal ... ###"
}
case "\${Var_disown_parser_yn}" in
	Y|y|Yes|yes|YES)
		${Var_echo_exec_path} "## \${Var_script_name} will differ cleanup trap assignment until after reading has from named pipe finished..."
	;;
	*)
		${Var_echo_exec_path} "## \${Var_script_name} will set exit trap now."
		trap "Clean_up_trap \${?}" EXIT
	;;
esac
Make_named_pipe(){
	if ! [ -p "\${Var_pipe_file_name}" ]; then
		${Var_mkfifo_exec_path} "\${Var_pipe_file_name}"
	fi
	${Var_chmod_exec_path} "\${Var_pipe_permissions}" "\${Var_pipe_file_name}"
	${Var_chown_exec_path} "\${Var_pipe_ownership}" "\${Var_pipe_file_name}"
	${Var_echo_exec_path} "# Starting \${Var_script_name} listener"
}
Rotate_output_file(){
	_count=\$((\${_count:-0}+1))
	if [ "\${_count}" -gt "\${Var_log_check_frequency}" ] || [ "\${_count}" = "\${Var_log_check_frequency}" ]; then
		if [ -f "\${Var_parsing_output_file}" ]; then
			_file_size=\$(du --bytes "\${Var_parsing_output_file}" | awk '{print \$1}' | head -n1)
			if [ "\${_file_size}" -gt "\${Var_log_max_size}" ]; then
				_now=\$(date +%s)
				_timestamp="\${_now}"
				for _actions in \${Var_log_rotate_actions//,/ }; do
					case "\${_actions}" in
						mv|move)
							${Var_mv_exec_path} "\${Var_parsing_output_file}" "\${Var_parsing_output_file}.\${_timestamp}"
						;;
						compress-encrypt|encrypt)
							${Var_tar_exec_path} -cz "\${Var_parsing_output_file}" | gpg --encrypt --recipient \${Var_log_rotate_recipient} --output "\${Var_parsing_output_file}.\${_timestamp}.tar.gz.gpg"
						;;
						encrypted-email)
							${Var_tar_exec_path} -cz "\${Var_parsing_output_file}" | gpg --encrypt --recipient \${Var_log_rotate_recipient} --output "\${Var_parsing_output_file}.\${_timestamp}.tar.gz.gpg"
							${Var_echo_exec_path} "Sent at \${_timestamp}" | mutt -s "\${Var_parsing_output_file}.\${_timestamp}.tar.gz.gpg" -a "\${Var_parsing_output_file}.\${_timestamp}.tar.gz.gpg" "\${Var_log_rotate_recipient}"
						;;
						compressed-email)
							${Var_tar_exec_path} -cz "\${Var_parsing_output_file}" "\${Var_parsing_output_file}.\${_timestamp}.tar.gz"
							${Var_echo_exec_path} "Sent at \${_timestamp}" | mutt -s "\${Var_parsing_output_file}.\${_timestamp}.tar.gz" -a "\${Var_parsing_output_file}.\${_timestamp}.tar.gz" "${_log_rotate_recipient}"
						;;
						compress)
							${Var_tar_exec_path} -cz "\${Var_parsing_output_file}" "\${Var_parsing_output_file}.\${_timestamp}.tar.gz"
						;;
						remove|rm|remove-old)
							${Var_rm_exec_path} -f "\${Var_parsing_output_file}"
							touch "\${Var_parsing_output_file}"
							${Var_chmod_exec_path} "\${Var_log_file_permissions}" "\${Var_parsing_output_file}"
							${Var_chown_exec_path} "\${Var_log_file_ownership}" "\${Var_parsing_output_file}"
						;;
					esac
				done
			fi
		fi
	fi
}
Map_read_array_to_output(){
	_file_or_pipe_to_map="\$1"
	## Make an array from input, note '-t' will "trim" last new-line.
	mapfile -t _lines < "\${_file_or_pipe_to_map}"
	let _count=0
	until [[ "\${Var_pipe_quit_string}" == "\${_lines[\${_count}]}" ]] || [ "\${_count}" = "\${#_lines[@]}" ] || [ "\${_count}" -gt "\${#_lines[@]}" ]; do
		case "\${Var_enable_padding_yn}" in
			y|Y|yes|Yes|YES)
				_line=( "\${_lines[\${_count}]}" )
				case "\${Var_padding_length}" in
					adaptive)
						_padding_length="\${#_lines[\${_count}]}"
					;;
					*)
						_padding_length="\${Var_padding_length}"
					;;
				esac
				for _option in \${Var_padding_placement//,/ }; do
					case "\${_option}" in
						append)
							Var_padding_command=\$(base64 /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c\${_padding_length})
							_line+=( "\${Var_padding_command}" )
						;;
						prepend)
							Var_padding_command=\$(base64 /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c\${_padding_length})
							_line=( "\${Var_padding_command}" "\${_line[@]}" )
						;;
					esac
				done
				for _option in \${Var_padding_placement//,/ }; do
					case "\${_option}" in
						above)
							Var_padding_command=\$(base64 /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c\${_padding_length})
							${Var_cat_exec_path} <<<"\${Var_padding_command}"
						;;
					esac
				done
				case "\${Var_preprocess_for_comments_yn}" in
					y|Y|yes|Yes|YES)
						case "\${_mapped_array}" in
							\${Var_parsing_comment_pattern})
								${Var_cat_exec_path} <<<"\${_line[@]}]//\${Var_parsing_allowed_chars}/}"
							;;
							*)
								${Var_cat_exec_path} <<<"# \${_line[*]//\${Var_parsing_allowed_chars}/}"
#								${Var_cat_exec_path} <<<"# \${_line[@]//\${Var_parsing_allowed_chars}/}"
							;;
						esac
					;;
					*)
						${Var_cat_exec_path} <<<"\${_line[@]}"
					;;
				esac
				let _count++
				for _option in \${Var_padding_placement//,/ }; do
					case "\${_option}" in
						bellow)
							Var_padding_command=\$(base64 /dev/urandom | tr -cd 'a-zA-Z0-9' | head -c\${_padding_length})
							${Var_cat_exec_path} <<<"\${Var_padding_command}"
						;;
					esac
				done
			;;
			*)
				case "\${Var_preprocess_for_comments_yn}" in
					y|Y|yes|Yes|YES)
						case "\${_mapped_array}" in
							\${Var_parsing_comment_pattern})
								${Var_cat_exec_path} <<<"\${_lines[\${_count}]//\${Var_parsing_allowed_chars}/}"
							;;
							*)
								${Var_cat_exec_path} <<<"# \${_lines[\${_count}]//\${Var_parsing_allowed_chars}/}"
							;;
						esac
					;;
					*)
						${Var_cat_exec_path} <<<"\${_lines[\${_count}]}"
					;;
				esac
#				echo "\${_lines[\${_count}]}"
			;;
		esac
	done
}
Pipe_parser_loop(){
	while [ -p "\${Var_pipe_file_name}" ]; do
		_mapped_array=\$(Map_read_array_to_output "\${Var_pipe_file_name}")
		PID_Map_read_array_to_output=\$!
		## If above variable is not zero characters in length OR if above variable
		##  is NOT equal to exit string, then push above variable through
		##  further checks, else signal 'brake' (false) to parent "while" loop.
		if ! [ -z "\${_mapped_array}" ] && ! [[ "\${Var_pipe_quit_string}" == "\${_lines[\${_count}]}" ]]; then
			if [ -f "\${_mapped_array}" ]; then
				if ! [ -d "\${Var_parsing_bulk_out_dir}" ]; then
					${Var_mkdir_exec_path} -p "\${Var_parsing_bulk_out_dir}"
				fi
				${Var_cat_exec_path} "\${_mapped_array}" | \${Var_parsing_command} >> "\${Var_parsing_bulk_out_dir}/\${_mapped_array##*/}\${Var_bulk_output_suffix}"

			elif [ -d "\${_mapped_array}" ]; then
				if ! [ -d "\${Var_parsing_bulk_out_dir}" ]; then
					${Var_mkdir_exec_path} -p "\${Var_parsing_bulk_out_dir}"
				fi
				${Var_tar_exec_path} zcf - "\${_mapped_array}" | \${Var_parsing_command} >> "\${Var_parsing_bulk_out_dir}/\${Var_star_date}_\${_mapped_array//\//_}.tgz\${Var_bulk_output_suffix}"
			else
				## Push mapped array through 'cat' then pipe results through encryption/decryption
				##  command, saving final results to output file.
				${Var_cat_exec_path} <<<"\${_mapped_array}" | \${Var_parsing_command} >> "\${Var_parsing_output_file}"
				## Check if script should load log-rotation function into this one
				##  if disabled then this should prevent a second or third process
				##  from being sent to the background/disown(ed)...
				case "\${Var_log_rotate_yn}" in
					y|Y|yes|Yes|YES)
						Rotate_output_file
					;;
				esac
			fi
		else
			break
		fi
	done
	_exit_code=\$?
	case "\${Var_disown_parser_yn}" in
		Y|y|Yes|yes|YES)
			${Var_echo_exec_path} "## \${Var_script_name} will execute [Clean_up_trap \$?] function now."
			Clean_up_trap "\${_exit_code}"
		;;
		*)
			${Var_echo_exec_path} "## \${Var_script_name} has already set trap for exit. Exit of last read showed [\${_exit_code}] exit code."
		;;
	esac
}
Make_named_pipe
case "\${Var_disown_parser_yn}" in
	Y|y|Yes|yes|YES)
		Pipe_parser_loop >"\${Var_dev_null}" 2>&1 &
		PID_Pipe_parser_loop=\$!
		disown \${PID_Pipe_parser_loop}
		${Var_echo_exec_path} "## \${Var_script_name} disowned PID [\${PID_Pipe_parser_loop}] & [\${PID_Map_read_array_to_output}] parsing loops"
	;;
	*)
		${Var_echo_exec_path} "## \${Var_script_name} will start parsing loop in this terminal"
		Pipe_parser_loop
	;;
esac
${Var_echo_exec_path} "# Quitting \${Var_script_name} listener"
set -o history
exit 0

EOF

		${Var_chmod_exec_path} "${Var_script_copy_permissions}" "${_script_copy_path}"
		${Var_chown_exec_path} "${Var_script_copy_ownership}" "${_script_copy_path}"
	else
		Func_messages "# Cannot overwrite preexisting [${_script_copy_path}] file" '2' '3'
	fi
}

## Function for Calling required functions in proper order to get things rolling.
Func_main(){
	if [ "${#@}" -gt "0" ]; then
		Func_check_args "${@}"
	fi
	Func_check_recipients
	Func_variable_assignment_reader
	case "${Var_save_options}" in
		y|Y|yes|Yes|YES)
			Func_save_options
		;;
	esac
	case "${Var_save_variables}" in
		y|Y|yes|Yes|YES)
			Func_save_variables
		;;
	esac
	case "${Var_script_copy_save}" in
		Y|y|Yes|yes|YES)
			if ! [ -z "${Var_script_copy_name}" ]; then
				Func_messages '#------# Func_save_copy messages' '1' '2'
				Func_save_copy "${Var_script_copy_name}"
				Func_messages '#------#' '1' '2'
				if ! [ -f "${Var_script_copy_name}" ]; then
					_exit_status=$?
					Func_messages "# Error: conflict within [Func_main] while using [${Var_script_copy_name}] variable" '0' '1'
					Func_messages "#  Attempting to check file and execute permissions on [${Var_script_copy_name}] file failed" '0' '1'
				else
					Func_messages "# Starting [${Var_script_copy_name}] with [${Var_script_name}] process" '1' '2'
					${Var_script_copy_name}
					_exit_status=$?
				fi
				Func_write_unrecognized_input_to_pipe
			else
				Func_messages "# Error: conflict within [Func_main] while using [${Var_script_copy_name}] variable" '0' '1'
				Func_messages "#  Attempting to check value length resulted in null [${Var_script_copy_name}] or empty value" '0' '1'
				exit 1
			fi
		;;
		*)
			Func_messages '# Notice: using internal read loop' '1' '2'
			Func_messages '#------# Func_mkfifo messages' '1' '2'
			Func_mkfifo
			Func_messages '#------# Func_mkpipe_reader messages' '1' '2'
			Func_messages "# Notice: listening loop on [${Var_pipe_file_name}] file path" '1' '2'
			Func_messages "#	Send output to the above path to have this listener on [${Var_script_name}] begin parsing" '1' '2'
			Func_messages '#	Send this listening loop to the background with [Ctrl^z] keyboard short cut and [bg] command' '1' '2'
			Func_messages '#	directly after to free up this terminal session' '1' '2'
			Func_messages "# Notice: to quit listening to this pipe and remove it with [echo \"${Var_pipe_quit_string}\" > ${Var_pipe_file_name}] command" '1' '2'
			Func_messages '#	or [Ctrl^c] keyboard shortcut while still attached to listening loop service' '1' '2'
			Func_messages '#------#' '1' '2'
			Func_messages "# What follows will be examples of commands about to be run as [${Var_script_name}] receives data to parse" '1' '2'
			case "${Var_disown_parser_yn}" in
				Y|y|Yes|yes|YES)
					Func_mkpipe_reader >"${Var_dev_null}" 2>&1 &
#					Func_mkpipe_reader &
					PID_Func_mkpipe_reader=$!
					disown "${PID_Func_mkpipe_reader}"
#					disown ${PID_Func_mkpipe_reader}
					case "${Var_save_encryption_yn}" in
						y|Y|yes|Yes|YES)
							Func_messages "# Notice: ${Var_script_name} disowned PID [${PID_Func_mkpipe_reader}] & [${PID_Map_read_array_to_output}] parsing loops" '1' '2'
							Func_messages "#  Parsed output will be saved to [${Var_parsing_output_file}] file" '1' '2'
						;;
						*)
							Func_messages "# Warning: ${Var_script_name} disowned PID [${PID_Func_mkpipe_reader}] & [${PID_Map_read_array_to_output}] parsing loops" '1' '2'
							Func_messages "#  However, parsed output will Not be saved to [${Var_parsing_output_file}] file!!!" '1' '2'
						;;
					esac
					Func_messages "# Notice: ${Var_script_name} disowned PID [${PID_Func_mkpipe_reader}] [${PID_Map_read_array_to_output}] parsing loops" '1' '2'
					Func_write_unrecognized_input_to_pipe
				;;
				*)
					Func_messages "# Notice: ${Var_script_name} will start parsing loop within current terminal" '1' '2'
					case "${Var_save_encryption_yn}" in
						y|Y|yes|Yes|YES)
							Func_messages "#  Parsed output will be saved to [${Var_parsing_output_file}] file" '1' '2'
						;;
						*)
							Func_messages "#  However, parsed output will Not be saved to [${Var_parsing_output_file}] file!!!" '1' '2'
						;;
					esac
					Func_mkpipe_reader
				;;
			esac
			_exit_status=$?
		;;
	esac
	Func_messages "# Reader [${Var_script_name}] exiting to interactive terminal with [${_exit_status}] status now" '1' '2'
#	Func_messages "## Turning bash history back on now..." '0' '1'
#	set -o history
}
## Call "Func_main" if no errors or quit signals have been received.
Func_main "${@:---help}"
