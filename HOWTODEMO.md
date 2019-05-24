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
     git remote add origin devnode:git/cncfdemo

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

Set up docker builder URL

    "Manage Jenkins" -> "Configure System" -> "Docker Builder" -> "URL" and set it to "unix:///var/run/docker.sock" (click test connection, and the save and apply)

Next set up webhook access. 

     "Manage Jenkins" -> "Configure Global Security" and check "Authorization" -> "Allow anonymous read access" and apply and save

then back to Jenkins dashboard and create new job. Name your job, perhaps "cncfdemo" and click "Freestyle project" and then "OK" at the bottom. Next fill in:

     Description: The CNCF demo
     Source code management: git
     Repository URL: devnode:git/cncfdemo
     Build Triggers: Check "Trigger build remotely", and then choose a random auth token, perhaps "cncfdemotoken"

Click save. 
Next as the demo user on devnode, create a file under ~/git/cncfdemo/hooks/post-commit with the following

     #!/bin/sh
     curl http://devnode:4000/job/cncfdemo/build?token=cncfdemotoken

Make it executable and now whenever you do a commit to the repo, a build will trigger for you. You can run the script manually or click on your job -> Build Now in the Jenkins web interface. You should get a  successful build completion.



....constantly being updated