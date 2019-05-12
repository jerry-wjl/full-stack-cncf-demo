Full Stack CNCF Demo Environment
================================

This repository is a way to demo a CNCF dev environmant to a customer site totally disconnected from a nework.
This should build hands off without any interaction. It works well on a 16GB laptop as there are 3 VM instances
created each 4GB. It has been tested on Linux and Mac without issues. It demonstrates several features from our
LOB including Virtualbox, kubernetes, and git, mongo, node all pulled from our local repos. Also jenkins (though not the X)
for pipeline demonstrations

The 3 VMS are all with Oracle Linux 7.6:

    1. devnode with IP 192.168.56.100. This contains the development enviroment. It will set up a user "demo".
       The generated id_rsa can be used to login to the system. This node contains kubectl, docker private
       registry with self signed SSL to hold the kubernetes images, jenkins, mongo and a git repository.
    2. kmaster  with IP 192168.56.101. This is the kubernetes master node.
    3. kworker1 with IP 192168.56.102. This is the kubernetes worker node.

Initalizing the environment
============================

If you've already pulled this repo on your local machine, you're good to go.

Starting by installing the virtualbox and vagrant for your environment.

Your OS may already have this as packaged product, else you may install it from

     https://www.virtualbox.org/wiki/Downloads

     https://www.vagrantup.com/downloads.html

Once installed you should start by downloading the oracle linux box 

     $ vagrant box add --name ol76 https://yum.oracle.com/boxes/oraclelinux/ol76/ol76.box
    

You will need to provide a file "ocr.txt" with 2 lines to suck the kubernetes images to the local
docker registry on the devnode. The content of this file is

       OCRUSER=xxxxx@oracle.com
       OCRPASS=yyyyyy

Now download the Vagrant file in the git repo and start it

     $ vagrant up

After some time you should now have a full development environment ready. It is suggested you
add the host ip/name combination to your local host file for demo purposes. So add

    192.168.56.100 devnode
    192.168.56.101 kmaster
    192.168.56.102 kworker1

Once done, on your local host (not vm) you should be able to go to the URL where jenkins is running

     http://devnode:4000

And you should get the jenkins welcome screen. You can login passwordless to the devnode as user demo using
    
     $ ssh demo@devnode -i id_rsa

You can check the status of the kubernetes cluster from the devnode (after you have logged in above) using

     $ kubectl get nodes

To destroy the gluster cluster

     $ vagrant destroy -f


Ports
=====

Jenkins is running on port 4000
docker registry is on port 5000

Next steps
==========

The next steps will show you how to build a shopping app and do a demo pusing it to the local repo on devnode
and then building a pipeline and deploying to kubernetes. Stay tuned. Link will appear here.