#!/usr/bin/bash

# Make sure the build environment is set up, and local variables are defined
. ./setup-env.sh

# Define the work directory for this script
export WORK_DIR=${ROOT_DIR}/output

#<<comment_reset_output_dir
########################################################################
# Start from scratch. Delete the output directory if it exists.
########################################################################

# force the removal of the output directory, and re-create it
rm -rf $WORK_DIR
mkdir $WORK_DIR

#comment_reset_output_dir

#<<commented
#########################################################################
# Pull the wikipedia word vectors off of the solr db
# Note: Mimics the hadoop output file names "part-r-00000" and "_SUCCESS"
# Note: Delete "--max 500" to pull all of the available data from solr
#########################################################################

echo "getting word vectors from solr"
${MAHOUT_HOME}/mahout lucene.vector \
	--dir $INDEX_DIR \
	--idField id \
	--field text --output ${WORK_DIR}/wiki-lucene-vec/tfidf-vectors/part-r-00000 \
	--dictOut ${WORK_DIR}/wiki-dict.txt \
	--seqDictOut ${WORK_DIR}/wiki.seq \
	--weight tfidf \
	--max 500

touch ${WORK_DIR}/wiki-lucene-vec/tfidf-vectors/_SUCCESS
#exit
#commented

#<<commented1
#########################################################################
# Pull the categories off of the solr db
# Note: Delete "-n 500 \" to pull all of the available data from solr
#########################################################################

export MAHOUT_INTEGRATION=${MAHOUT_WIKI_REPO}/integration
${MAVEN_HOME}/mvn -f ${MAHOUT_INTEGRATION}/pom.xml package -DskipTests
mv ${MAHOUT_INTEGRATION}/target/*.jar ${WORK_DIR}

echo "generating categories file"
#java -jar lucene2cats.jar \
java -cp ${WORK_DIR}/mahout-integration-0.9.jar org.apache.mahout.text.SequenceFilesFromLuceneStorageDriver \
-i ${INDEX_DIR} \
-o ${WORK_DIR}/wiki-cats-seq \
-id id \
-f categories \
-n 500 \
-xm sequential

#exit
#commented1

#<<commented2
#########################################################################
# Assign categories to the word vectors, based on their common id
#########################################################################

echo "compiling lucene_cats_combine"
${MAVEN_HOME}/mvn -f ${WIKITWEET_REPO}/pom.xml package -DskipTests
mv ${WIKITWEET_REPO}/target/*.jar ${WORK_DIR}

echo "combining catagory and term vector sequence files"
#java -jar lucene_cats_combine.jar \
java -cp ${WORK_DIR}/lucene_cats_combine-0.1.jar com.wikitweet.tools.lucene_cats_combine \
${WORK_DIR}/wiki-lucene-vec/tfidf-vectors/part-r-00000 \
${WORK_DIR}/wiki-cats-seq/index \
${WORK_DIR}/combined_out

#exit
#commented2

#<<commented3
#######################################################################
# Split the data for cross-validation
#######################################################################

echo "Creating training and holdout set with a random 80-20 split of the generated vector dataset"
${MAHOUT_HOME}/mahout split \
    -i ${WORK_DIR}/combined_out \
    --trainingOutput ${WORK_DIR}/wiki-train-vectors \
    --testOutput ${WORK_DIR}/wiki-test-vectors  \
    --randomSelectionPct 20 --overwrite --sequenceFiles -xm sequential

exit
#commented3

<<commented4
#######################################################################
# Train the NB model on the training data set
#######################################################################

echo "Training Naive Bayes model"
${MAHOUT_HOME}/mahout trainnb \
    -i ${WORK_DIR}/wiki-train-vectors -el \
    -o ${WORK_DIR}/model \
	-ow $c \
    -li ${WORK_DIR}/labelindex \
    
exit
commented4

<<commented5
#######################################################################
# Test the NB model on the training data set.
# This gives you the in-sample accuracy.
#######################################################################

echo "Self testing on training set"
${MAHOUT_HOME}/mahout testnb \
    -i ${WORK_DIR}/wiki-train-vectors\
    -m ${WORK_DIR}/model \
    -l ${WORK_DIR}/labelindex \
    -ow -o ${WORK_DIR}/wiki-testing $c

exit
commented5

<<commented6
#######################################################################
# Test the NB model on the testing data set.
# This gives you the out-of-sample accuracy.
#######################################################################

echo "Testing on holdout set"
${MAHOUT_HOME}/mahout testnb \
    -i ${WORK_DIR}/wiki-test-vectors\
    -m ${WORK_DIR}/model \
    -l ${WORK_DIR}/labelindex \
    -ow -o ${WORK_DIR}/wiki-testing $c

exit
commented6
