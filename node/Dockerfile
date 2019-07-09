FROM oraclelinux
RUN yum -y install oracle-nodejs-release-el7
RUN yum -y --disablerepo=ol7_developer_EPEL install nodejs
ADD package.json /package.json
RUN (cd /; npm i)
ENV NODE_PATH /node_modules
RUN node --version
