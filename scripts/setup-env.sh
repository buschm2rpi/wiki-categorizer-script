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
export ROOT_DIR=../$(pwd)

#########################################################################
# Get the official maven, mahout, and hadoop distributions
# Note: Do not comment out this section. It should run every time.
#########################################################################

# download and unpackage maven 3.0.5
if [ ! -f "${ROOT_DIR}/maven/_SUCCESS" ]; then
  rm -rf ${ROOT_DIR}/maven &&
  mkdir ${ROOT_DIR}/maven &&
  wget -P ${ROOT_DIR}/maven/ http://mirrors.advancedhosters.com/apache/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz &&
  tar xzvf ${ROOT_DIR}/maven/apache-maven-3.0.5-bin.tar.gz -C ${ROOT_DIR}/maven/ &&
  touch ${ROOT_DIR}/maven/_SUCCESS
fi

export MAVEN_HOME=${ROOT_DIR}/maven/apache-maven-3.0.5/bin

# mahout 0.9: download, unpackage, and install using local version of maven 
if [ ! -f "${ROOT_DIR}/mahout/_SUCCESS" ]; then
  rm -rf ${ROOT_DIR}/mahout &&
  mkdir ${ROOT_DIR}/mahout &&
  wget -P ${ROOT_DIR}/mahout/ http://mirror.cogentco.com/pub/apache/mahout/0.9/mahout-distribution-0.9-src.tar.gz &&
  tar xzvf ${ROOT_DIR}/mahout/mahout-distribution-0.9-src.tar.gz -C ${ROOT_DIR}/mahout/ &&
  ${MAVEN_HOME}/mvn -f ${ROOT_DIR}/mahout/mahout-distribution-0.9/pom.xml install -DskipTests &&
  touch ${ROOT_DIR}/mahout/_SUCCESS
fi

export MAHOUT_HOME=${ROOT_DIR}/mahout/mahout-distribution-0.9/bin
export MAHOUT_LOCAL=true

# download and unpackage hadoop 2.5.1
if [ ! -f "${ROOT_DIR}/hadoop/_SUCCESS" ]; then
  rm -rf ${ROOT_DIR}/hadoop &&
  mkdir ${ROOT_DIR}/hadoop &&
  wget -P ${ROOT_DIR}/hadoop/ http://mirror.nexcess.net/apache/hadoop/common/hadoop-2.5.1/hadoop-2.5.1.tar.gz &&
  tar xzvf ${ROOT_DIR}/hadoop/hadoop-2.5.1.tar.gz -C ${ROOT_DIR}/hadoop/ &&
  touch ${ROOT_DIR}/hadoop/_SUCCESS
fi

export HADOOP_HOME=${ROOT_DIR}/hadoop/hadoop-2.5.1/bin

# make sure directory exists, which will hold data from Dan Richman's programs
if [ ! -d "${ROOT_DIR}/ddr_data" ]; then
  mkdir ${ROOT_DIR}/ddr_data
fi
export DDR_DIR=${ROOT_DIR}/ddr_data

# update PATH. note: this is probably redundant since I explicitly call the local installations
export PATH=${HADOOP_HOME}:${MAHOUT_HOME}:${MAVEN_HOME}:${PATH}

#########################################################################
# Get the wikitweet project specific source code from github
# Note: Do not comment out this section. It should run every time.
#########################################################################

# download the project's git repositories so they can be compiled later
if [ ! -f "${ROOT_DIR}/git-local/_SUCCESS" ]; then
  rm -rf ${ROOT_DIR}/git-local &&
  mkdir ${ROOT_DIR}/git-local &&
  git clone https://github.com/buschm2rpi/mahout.git ${ROOT_DIR}/git-local/mahout -b WikiTweets &&
  git clone https://github.com/buschm2rpi/WikiTweet.git ${ROOT_DIR}/git-local/wikitweet &&
  git clone https://github.com/buschm2rpi/wikicategories.git ${ROOT_DIR}/git-local/wikicategories -b Vanilla_TAQOS &&
  touch git-local/_SUCCESS
fi

# set git directory variables
export WIKITWEET_REPO=${ROOT_DIR}/git-local/wikitweet
export MAHOUT_WIKI_REPO=${ROOT_DIR}/git-local/mahout
export WIKICATEGORIES_REPO=${ROOT_DIR}/git-local/wikicategories

# sync the git repos. need to go into those directories first
cd ${MAHOUT_WIKI_REPO} &&
git fetch https://github.com/buschm2rpi/mahout.git WikiTweets &&
git merge WikiTweets

cd ${WIKITWEET_REPO} &&
git fetch https://github.com/buschm2rpi/WikiTweet.git master &&
git merge master

cd ${WIKICATEGORIES_REPO} &&
git fetch https://github.com/buschm2rpi/wikicategories.git Vanilla_TAQOS &&
git merge Vanilla_TAQOS

cd ${ROOT_DIR}

echo "Setup Complete"
