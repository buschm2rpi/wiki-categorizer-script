#!/usr/bin/bash

########################################################################
# Project specific parameters for your machine can be defined here.
# Everything else is automated by this script to be set up locally.
########################################################################

# Choose your Java JDK
export JAVA_HOME=/opt/jdk1.7.0_71/

# specify the location of the solr index
export SOLR_DIR=/home/mbusch/solr-4.6.1/example
export INDEX_DIR=$SOLR_DIR/solr/collection1/data/index

#########################################################################
#########################################################################
#
# BEWARE. You shouldn't need to change anything below this line.
#
#########################################################################
#########################################################################

# set the projects root directory to the same directory where this file lives
export ROOT_DIR=$(pwd)

#########################################################################
# Get the official maven, mahout, and hadoop distributions
# Note: Do not comment out this section. It should run every time.
#########################################################################

# download and unpackage maven 3.0.5
if [ ! -f "maven/_SUCCESS" ]; then
  rm -rf maven &&
  mkdir maven &&
  wget -P maven/ http://mirrors.advancedhosters.com/apache/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz &&
  tar xzvf maven/apache-maven-3.0.5-bin.tar.gz -C maven/ &&
  touch maven/_SUCCESS
fi

export MAVEN_HOME=${ROOT_DIR}/maven/apache-maven-3.0.5/bin

# mahout 0.9: download, unpackage, and install using local version of maven 
if [ ! -f "mahout/_SUCCESS" ]; then
  rm -rf mahout &&
  mkdir mahout &&
  wget -P mahout/ http://mirror.cogentco.com/pub/apache/mahout/0.9/mahout-distribution-0.9-src.tar.gz &&
  tar xzvf mahout/mahout-distribution-0.9-src.tar.gz -C mahout/ &&
  ${MAVEN_HOME}/mvn -f ${ROOT_DIR}/mahout/mahout-distribution-0.9/pom.xml install -DskipTests &&
  touch mahout/_SUCCESS
fi

export MAHOUT_HOME=${ROOT_DIR}/mahout/mahout-distribution-0.9/bin
export MAHOUT_LOCAL=true

# download and unpackage hadoop 2.5.1
if [ ! -f "hadoop/_SUCCESS" ]; then
  rm -rf hadoop &&
  mkdir hadoop &&
  wget -P hadoop/ http://mirror.nexcess.net/apache/hadoop/common/hadoop-2.5.1/hadoop-2.5.1.tar.gz &&
  tar xzvf hadoop/hadoop-2.5.1.tar.gz -C hadoop/ &&
  touch hadoop/_SUCCESS
fi

export HADOOP_HOME=${ROOT_DIR}/hadoop/hadoop-2.5.1/bin

# update PATH. note: this is probably redundant since I explicitly call the local installations
export PATH=${HADOOP_HOME}:${MAHOUT_HOME}:${MAVEN_HOME}:${PATH}

#########################################################################
# Get the wikitweet project specific source code from github
# Note: Do not comment out this section. It should run every time.
#########################################################################

# download the project's git repositories so they can be compiled later
if [ ! -d "git-local" ]; then
  mkdir git-local
  git clone https://github.com/buschm2rpi/mahout.git git-local/mahout -b WikiTweets
  git clone https://github.com/buschm2rpi/WikiTweet.git git-local/wikitweet 
fi

# set git directory variables
export WIKITWEET_REPO=${ROOT_DIR}/git-local/wikitweet
export MAHOUT_WIKI_REPO=${ROOT_DIR}/git-local/mahout

# sync the git repos. need to go into those directories first
cd ${MAHOUT_WIKI_REPO} &&
git fetch https://github.com/buschm2rpi/mahout.git WikiTweets &&
git merge WikiTweets

cd ${WIKITWEET_REPO} &&
git fetch https://github.com/buschm2rpi/WikiTweet.git master &&
git merge master

cd ${ROOT_DIR}

echo "Setup Complete"
