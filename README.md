#### Usage

Script assumes the following:

1. User is running a Bash shell.
2. User is installing to a Oracle instance

#### DevLog

##### 230906

The goal of this project is to automatically push a container to a self-made Kubernetes cluster.

##### 230907

NOTHING WORKS. Yesterday I was fighting with Oracle Linux to create two free tier arm instances despite the constant out of capacity errors. Today I got an instance on one of my accounts and wanted to install Kubesphere and Kubernetes via Kubekey. But Kubekey keeps installing amd64 dependencies and there is no documentation on changing Kubekey's target arch. Kubesphere simply states that arm64 is not fully supported yet. Guess I need to manually install.

Anyway, I have two free tier Oracle Linux instances that I want to link via Kubernetes. I decided after much discord question asking that linking them via Master -> Worker in one cluster over a public network was a big security risk. Instead I am going to make both of them both Masters and Workers. That way I have two clusters but greater security. I considered converting my Oracle Linux instances to 4 2 ocpu 12 gb ram instead of 2 4 ocpu and 24 gb ram but whatever I am lazy and it doesn't fix the previous problem.

##### 2309011

I tried to create Kubernetes manually via the command line, but cri-o couldn't be installed because the glibc version was too low. I searched around updating yum's repos for later versions of glibc but the only solution I found was manually installing glibc. I really tried finding a way around that, but in the end I attempted the install. Glibc install threw and error saying "mathvec is enabled but compiler does not have SVE ACLE". So I figured I needed to install a newer version of GCC but at that point I wanted to try a new way.

Remember I searched around updating yum's repos? Well one of the articles I read were on updating from Oracle Linux 8 to Oracle Linux 9. I looked at my instance and it was using Oracle Linux 8. Why wasn't the latest version of Oracle Linux the default? Deleting that intance and creating a Oracle Linux 9 instance solved my problems. So I continued installing Kubernetes.

##### 230914

I do not have enough time to install kubernetes manually. I want an automated way. Turns out there is a setup script for ARM machines. I found k3sup.

##### 230915

I really wanted to wrap k3sup in a Bash Gum script. IDK why but now I can setup clusters easier. Probably should gather the whole clusters information instead of setting up each node one by one but oh well.
