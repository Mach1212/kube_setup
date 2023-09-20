#!/usr/bin/bash

handle_error() {
	EXIT_STATUS=$?
	if [ $EXIT_STATUS != 0 ]; then
		echo $1: $EXIT_STATUS
		exit
	fi
}
handle_termination() {
	if [ $? = 130 ]; then
		exit
	fi
}
final() {
	gum confirm "Setup bash-completions?" && [[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] &&
		. /usr/share/bash-completion/bash_completion
	exit
}
main() {
	gum filter <<<"random" &>/dev/null
	handle_error "Download Charmbracelet Gum"

	k3sup
	if [ $? = 127 ]; then
		echo 'Downloading k3sup'

		if ! sudo curl -sLS https://get.k3sup.dev | sudo sh; then
			printf "\nSomething unexpected occured during k3sup install...\n"
			exit
		fi
	fi
	kubectl
	handle_error "Download kubectl"

	while true; do
		NODE_TYPE=$(gum choose --header "Setup node" --limit 1 "master" "worker") || exit
		MASTER_IP=$(gum input --header 'Master IP' --value "$MASTER_IP") || exit
		MASTER_SSH_USER=$(gum input --header 'SSH User' --value "$MASTER_SSH_USER") || exit
		if [ -z "$SSH_KEY_VALUE" ]; then
			SSH_KEY_VALUE='~/.ssh/id_rsa'
		fi
		SSH_KEY=$(gum input --header 'Private SSH Key' --value "$SSH_KEY_VALUE") || exit

		if [ "$NODE_TYPE" = "master" ]; then
			echo "Installing master..."

			k3sup install \
				--ip "$MASTER_IP" \
				--user "$MASTER_SSH_USER" \
				--ssh-key "$SSH_KEY" \
				--sudo
			handle_error "k3sup failed to install on $MASTER_IP"

			printf '\nKubernetes installed, everything else is optional'
			printf 'Make sure to disable cloud firewall\n'
			printf "\nEnsure port 6443 is open.\n"

			if [ -f "$(pwd)/kubeconfig" ]; then
				echo "Kubeconfig not in default directory. Unable to set environment."
			else
				export KUBECONFIG
				KUBECONFIG="$(pwd)/kubeconfig"
				gum confirm "Set KUBECONFIG in .bashrc?" &&
					echo "export KUBECONFIG=\"$(pwd)/kubeconfig\"" >>~/.bashrc
			fi

			gum confirm "Alias kc to kubectl in .bashrc?" &&
				echo "alias kc=kubectl" >>~/.bashrc &&
				alias kc=kubectl
		else
			echo "Joining worker..."
			k3sup join \
				--ip "$(gum input --placeholder 'Worker node IP')" \
				--user "$(gum input --placeholder 'Worker SSH User' --value "$MASTER_SSH_USER")" \
				--server-ip "$MASTER_IP" \
				--server-user "$MASTER_SSH_USER" \
				--ssh-key "$SSH_KEY" \
				--sudo
		fi

		gum confirm 'Setup another node?' || final
	done
}
main
