#!/usr/bin/sh

K3SUPS_EXE_PATH='/usr/local/bin/k3sup'

if [ -f "$K3SUPS_EXE_PATH" ]; then
	echo 'Skipping k3sup install...'
else
	gum confirm "Ok to install k3sup?" || exit
	echo 'Downloading k3sup'
	sudo curl -sLS https://get.k3sup.dev | sudo sh
fi

while true; do
	NODE_TYPE=$(gum choose --header "Setup node" --limit 1 "master" "worker") || exit

	MASTER_IP=$(gum input --header 'Master IP' --value "$MASTER_IP")
	MASTER_SSH_USER=$(gum input --header 'SSH User' --value "$MASTER_SSH_USER")
	if [ -z "$SSH_KEY_VALUE" ]; then
		SSH_KEY_VALUE='~/.ssh/id_rsa'
	fi
	SSH_KEY=$(gum input --header 'Private SSH Key' --value "$SSH_KEY_VALUE")

	if [ "$NODE_TYPE" = "master" ]; then
		echo "Installing master..."

		k3sup install \
			--ip "$MASTER_IP" \
			--user "$MASTER_SSH_USER" \
			--ssh-key "$SSH_KEY" \
			--sudo

		gum confirm "Disable master firewall?" && 
			ssh "$MASTER_SSH_USER"@"$MASTER_IP" -i "$SSH_KEY" "sudo systemctl stop firewalld && sudo systemctl disable firewalld"

		if [ -f "$(pwd)/kubeconfig" ]; then
			gum confirm "Set KUBECONFIG in .bashrc?" &&
				echo "export KUBECONFIG=\"$(pwd)/kubeconfig\"" >>~/.bashrc
			gum confirm "Alias kc to kubectl in .bashrc?" &&
				echo "alias kc=kubectl" >>~/.bashrc &&
				alias kc=kubectl
			export KUBECONFIG
			KUBECONFIG="$(pwd)/kubeconfig"
		else
			echo "Kubeconfig not in default directory. Unable to set environment."
		fi

		echo ""
		echo "Ensure firewall is disabled!"
		echo "Ensure port 6443 is open!"
		echo "Test cluster via \"kubectl get nodes\""
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

	gum confirm 'Setup another node?' || exit

done
