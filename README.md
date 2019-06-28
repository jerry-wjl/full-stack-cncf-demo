Full Stack CNCF Demo Environment
================================

This repository is a way to demo a CNCF dev environmant to a customer site totally disconnected from a nework.
This should build hands off without any interaction. It works well on a 16GB laptop as there are 3 VM instances
created each of 4GB. It has been tested on Linux, Mac, and Windows without issues. It demonstrates several features from our
LOB including Virtualbox, kubernetes, and git, mongo, node all pulled from our local repos. Also jenkins (though not
the X version) for CI/CD pipeline demonstrations

The 3 VMS are all with Oracle Linux 7.6:

* **devnode** with IP 192.168.56.200. This contains the development enviroment. 
    * It will set up a user "demo". The generated id_rsa can be used to login to the system. This node contains kubectl, docker private
registry with self signed SSL to hold the kubernetes images, jenkins, mongo and a git repository.
* **kmaster**  with IP 192.168.56.201. This is the kubernetes master node.
* **kworker1** with IP 192.168.56.202. This is the kubernetes worker node.

Initalizing the environment
============================

If you've already pulled this repo on your local machine, you're good to go. If not, clone the repo as follows.

`git clone https://github.com/olsc-devops/full-stack-cncf-demo.git`

Starting by installing Virtualbox and Vagrant for your platform.

Your OS may already have this as packaged product, otherwise you may install it from

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

* [Vagrant](https://www.vagrantup.com/downloads.html)

Once installed you should start by downloading the Oracle Linux box 

     $ vagrant box add --name ol76 https://yum.oracle.com/boxes/oraclelinux/ol76/ol76.box
    
Next, sign in to [Oracle Container Registry](https://container-registry.oracle.com) and accept the Oracle Standard Terms and Restrictions for *both* the **Container Services** and the **Container Services (Developer) Repositories**.

You will need to provide a file called "ocr.txt" with 2 lines to suck the kubernetes images to the local
docker registry on the devnode. This should be in the `full-stack-cncf-demo` directory. The contents of the Oracle Container Registry ocr.txt file should consist of 2 lines

       OCRUSER=xxxxx@oracle.com
       OCRPASS=yyyyyy

Next and start the environment as follows

     $ vagrant up

Ensure you remove the ocr.txt file immediately after you see the kmaster build messages (i.e.
the devnode VM has completed pulling all the nodes from the OCR)

After some time you should now have a full development environment ready to use. It is suggested you
add the host ip/name combination to your local host file for demo purposes. So add the following to your local hosts file.

    192.168.56.200 devnode
    192.168.56.201 kmaster
    192.168.56.202 kworker1
   
Post Initialization Checks
--------------------------

Once completed, on your local host (not vm), you should be able to go to the URL where Jenkins is running

[http://devnode:4000](http://devnode:4000)

<img src="img/jenkins_init_login.png" alt="initial jenkins login" width="747px" height="703px">

and you should get the Jenkins welcome screen. Don't bother attempting to login and configure Jenkins yet, we will cover how to configure Jenkins in detail later. For now, you can just confirm that Jenkins was deployed by visiting the URL above.

Next, login to the `devnode` as user `demo` as follows
    
 <img src="img/021a-jenkins.png" alt="devnode login" width="990px" height="393px">

 Check the status of the kubernetes cluster from the devnode (after you have logged in above) using

<img src="img/001-PostInitChecks.png" alt="kubectl get nodes" width="584px" height="113px">
 

Rebuilding the Environment
--------------------------

To destroy all the nodes

     $ vagrant destroy -f

However it is not suggested to do this due to the length of time required to rebuild and pull images from OCR to the
devnode. If you ever need to rebuild the kubenetes cluster you can just

     $ vagrant destroy -f kmaster kworker1
     $ vagrant up kmaster kworker1

Which should build a clean kubernetes cluster in a few minutes since it will pull from the docker registry on devnode.
You can quickly demo how easy it is to build a kubernetes cluster to a customer.

For a more detailed version of how to reset your environment, see HowToResetTheEnv.

Ports
=====

These are the open ports on devnode

      jenkins is running on port 4000
      docker registry is on port 5000
      mongodb on 27017
      git is accessible via ssh port 22

Docker images 
=============

These are images available in the local docker registry on devnode

      coredns 
      bbc-grafana
      bbc-prometheus
      etcd                       
      flannel                    
      grafana                    
      k8s-dns-dnsmasq-nanny      
      k8s-dns-kube-dns           
      k8s-dns-sidecar            
      kube-apiserver             
      kube-controller-manager    
      kube-proxy                 
      kube-scheduler             
      kubernetes-dashboard-amd64 
      node                       
      pause                      
      prometheus                 
      registry    
      
Next steps
==========

The next steps will show you how to build a shopping app and do a demo pusing it to the local repo on devnode
and then building a pipeline and deploying to kubernetes. Start by clicking [here](CONFIGDEMO.md) to learn how to set up the demo environment.
