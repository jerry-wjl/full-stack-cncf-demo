Running the First Build
-----------------------

Login as `demo` to the `devnode`

<img src="../img/021a-jenkins.png" alt="ssh login as demo" width="990px" height="393px">

Clone the bbc app in your home dir

`git clone https://github.com/olsc-devops/bbc`

<img src="../img/git_clone_bbc_devnode.png" alt="git clone bbc" width="751px" height="211px">

Next we will add the bbc repository to the git repo on devnode. First, we remove all past commits and set up our repo.

     cd bbc
     rm -rf .git
     git init
     git remote add origin demo@devnode:git/cncfdemo

<img src="../img/002-firstjenksbld.png" alt="clean repo for local import" width="817px" height="156px"> 

Before we can complete a successful build we need to run the following command

    $ npm install

<img src="../img/008-firstjenksbld.png" alt="npm install" width="1107px" height="67px">

<img src="../img/009-firstjenksbld.png" alt="npm install complete" width="354px" height="336px">

Next we need to populate the database.

    $ export MONGODB=mongodb://localhost/cncfdemo
    $ node populate.js ./cars.json

<img src="../img/010-firstjenksbld.png" alt="populate database" height="352px" height="102px">

Now that that's done it's time to set up our userid and email so we know who is interacting with the local repo. You can choose anything you like here (no emails or user
names are leaked)

    git config --global user.email "demo@oracle.com"
    git config --global user.name "CNCF Demo"
    git config --list

<img src="../img/003-firstjenksbld.png" alt="git config" width="925px" height="300px">

Now add a .gitignore and push everything else to our local repo

    printf 'README.md\nnode_modules\npackage-lock.json\n.gitignore' >.gitignore
    git add .
    git commit -a -m 'Initial commit'
    git push -u origin master

<img src="../img/004-firstjenksbld.png" alt=".gitignore" width="1152px" height="84px">

<img src="../img/005-firstjenksbld.png" alt="git commit" width="877px" height="938px">

<img src="../img/006-firstjenksbld.png" alt="git push" width="763px" height="253px">

Now go to your Jenkins Dashboard and click on the `cncfdemo` link to view the progress and status of your build.

<img src="../img/007-firstjenksbld.png" alt="jenkins dashboard" width="1080px" height="184px">

<img src="../img/011-firstjenksbld.png" alt="cncf pipline" width="936px" width="228px">

If you configured everything correctly, you will see the progress of your build.

<img src="../img/012-firstjenksbld.png" alt="cncf pipline progress" width="935px" width="317px">

<img src="../img/013-firstjenksbld.png" alt="cncf pipline complete" width="936px" width="302px">

Once compelte, go to the application page [Billionares Buyers Club](http://devnode:30000/#!/)

<img src="../img/014-firstjenksbld.png" alt="bbc" width="935px" height="478px">

...and you're done!

Next Steps
----------

* [Demo flow](https://github.com/olsc-devops/bbc/blob/docs-dev/docs/DEMOFLOW.md) - for those using vagrant boxes (aka [Full Stack Demo](https://olsc-devops.github.io/full-stack-cncf-demo/))
* [How to Independently Run the Demo](https://github.com/olsc-devops/bbc/blob/docs-dev/docs/INDEPENDENTRUN.md) ...for those of you not using the vagrant boxes