Running the demo
================

Assumptions

	1. You are using the full-stack-cncf-demo vagrant setup
	2. You have added hosts 192.168.56.200, 192.168.56.201, 192.168.56.202 in /etc/hosts as devnode, kmaster and kworker1


Login to the devnode as user demo (you should be in the full-stack-cncf-demo directory)

      ssh -i id_rsa demo@devnode

Pull the bbc app in your home dir

     git clone https://github.com/olsc-devops/bbc

Since we will be running this repo as a local disconnected demo we need to switch from the remote to the git repo on devnode. So we
remove all past commits and set up our repo

     cd bbc
     rm -rf .git
     git init
     git remote add origin demo@devnode:git/cncfdemo

Set up our userid and email so we know who is interacting with the local repo. You can choose anything you like here (no emails or user
names are leaked)

    git config --global user.email "demo@oracle.com"
    git config --global user.name "CNCF Demo"

Now add a .gitignore and push everything else to our local repo

    printf 'README.md\nnode_modules\npackage-lock.json\n.gitignore' >.gitignore
    git add .
    git commit -a -m 'Initial commit'
    git push -u origin master


Setting up Jenkins CI/CD
========================

You will probably have missed the password messages when building the vagrant infrastructure. You can get this from

    /home/demo/.jenkins/secrets/initialAdminPassword

So just go to the URL on devnode http://devnode:4000 and enter that in. Click on "Install Suggested Plugins" and wait
a while. You will end up at "Create First Admin User" page. Finish filling that in and you should end up at "Instance Configuration".
Ensure you don't have localhost as the hostname, but a proper hostname. Hopefully you would have take heed at the begining of this
document and added the host "devnode" in your hosts file and/or dns so you can get to this machine by name. Click "Finish" and you should
be logged into Jenkins.

Now that you are in, click on

    "Manage Jenkins" -> "Manage Plugins" -> "Check Now" and wait to complete

Next click on the "Available" tab and then seach for Kubernetes in the "Filter" box. Check the "Kubernetes" plugin and select "Install without restart" button. Next add the "docker-build-step" plugin the same way as above.

Next go to main dashboard and click on "New Item" on the top left. Enter "Item Name" as "cncfdemo" and click "Pipeline" and "OK" at the bottom. You will open in a config page for this pipeline.
Set the following fields:


     Description: The CNCF demo
     Build Triggers: Check "Trigger build remotely", and then choose a random auth token, perhaps "cncfdemotoken" but must match the value in the post-commit trigger script below
     Pipeline -> Definintion: Choose Pipeline from SCM
     Pipeline -> SCM (Source code management): git
     Pipeline -> Repositories: devnode:git/cncfdemo
     Pipeline -> Script Path: Jenkinsfile


Next set up webhook access. 

     "Manage Jenkins" -> "Configure Global Security" and check "Authorization" -> "Allow anonymous read access" and apply and save


Click save. 
Next as the demo user on devnode, create a file under ~/git/cncfdemo/hooks/post-receive with the following

     #!/bin/sh
     curl http://devnode:4000/job/cncfdemo/build?token=cncfdemotoken

Make it executable and now whenever you do a commit to the repo, a build will trigger for you. Test by using an editor of your choice and commit your change to the repo (devnode:git/cncfdemo) and a build will automatically trigger.

You can run the script manually or click on your job -> Build Now in the Jenkins web interface. You should get a successful build completion.

Optional step: Set up docker builder URL (optional for freestyle projects)

    "Manage Jenkins" -> "Configure System" -> "Docker Builder" -> "URL" and set it to "unix:///var/run/docker.sock" (click test connection, and the save and apply)

Now you can build your docker images (grafana, prometheus etc) using the gui.

Kubernetes dasboard
===================

To get to the kubernetes dashboard on kmaster, you would need to first get the login token. On devnode please run

      kubectl -n kube-system describe $(kubectl -n kube-system get secret -n kube-system -o name | grep namespace) | grep token:

Now browse to the link

      http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login

and use the token from above

**You are all set up now to do the whole demo**

How to demo the app
===================

Typically you can show 4 things.

	  1. Populate the database with new data (will not trigger a build)
	  2. Edit a file in git and commit it (will trigger a build and rolling upgrade)
	  3. Scale up kubernetes deployment (edit kubernetes/cncfdemo.yml and commit which will trigger a build and rolling upgrade)
	  4. Show metrics - i.e do some sales and show real time data getting populated.



....constantly being updated
