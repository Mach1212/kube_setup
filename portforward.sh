#!/usr/bin/bash

handle_termination() {
	if [ $? = 130 ]; then
		exit
	fi
}
handle_error() {
	local EXIT_STATUS=$?
	if [ "$EXIT_STATUS" != 0 ]; then
		echo $1: $EXIT_STATUS
		exit
	fi
}
handle_error_gracefully() {
	local EXIT_STATUS=$?
	if [ "$EXIT_STATUS" != 0 ]; then
		echo $1: $EXIT_STATUS
	fi
}
remote_execute() {
	ssh "$SSH_USER"@"$IP" -i "$SSH_KEY" "$1"
}
list_ports() {
	local PORTS=$(remote_execute "sudo firewall-cmd --list-ports")
	handle_error "Unable to list port info"

	if [ -z "$PORTS" ]; then return; fi

	tr ' ' '\n' <<<"$PORTS"
}
open_port() {
	local PROTOCOL=$(gum filter --header "Protocol" <<<"$(printf "tcp\nudp")") || return
	local PORT=$(gum input --header "Port") || return

	echo "Open ${PORT}/${PROTOCOL}..."
	remote_execute "sudo firewall-cmd --permanent --zone=public --add-port=${PORT}/${PROTOCOL} && sudo firewall-cmd --reload > /dev/null"
	handle_error_gracefully "Unable to open ${PORT}/${PROTOCOL} in firewall"
}
close_port() {
	remote_execute "sudo firewall-cmd --permanent --zone=public --remove-port=$SELECTED_PORT && sudo firewall-cmd --reload > /dev/null"
	handle_error_gracefully "Unable to close $SELECTED_PORT in firewall"
}
main() {
	echo "Port Manager"

	IP=$(gum input --header 'IP') || exit
	handle_termination
	SSH_USER=$(gum input --header 'SSH User' --value "opc") || exit
	handle_termination
	SSH_KEY=$(gum input --header 'Private SSH Key' --value "~/.ssh/id_rsa") || exit
	handle_termination

	while true; do
		local PORT_LIST=$(list_ports)
		if [ -n "$PORT_LIST" ]; then
			PORT_LIST="$(awk '{print "Remove " $0;}' <<<"$PORT_LIST")\n"
		fi
		FORMATTED_SELECTED_PORT="$(gum filter --header "Port select" <<<"$(printf "${PORT_LIST}Add port\nExit")")" || exit
		SELECTED_PORT=$(sed 's/Remove //g' <<<"$FORMATTED_SELECTED_PORT")

		handle_termination
		if [ "$SELECTED_PORT" = "Exit" ]; then
			break
		elif [ "$SELECTED_PORT" = "Add port" ]; then
			open_port
		else
			close_port
		fi
	done
}
main
