#!/usr/bin/bash

# Make sure the build environment is set up, and local variables are defined
. ./setup-env.sh
# exit
# Define the work directory for this script
export WORK_DIR=${ROOT_DIR}/output

#<<comment_reset_output_dir
########################################################################
# Start from scratch. Delete the output directory if it exists.
########################################################################
#<<comment_reset_output_dir
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

echo "getting word vectors from solr"
${MAHOUT_HOME}/mahout lucene2seq \
	-i ${INDEX_DIR} \
	-id id \
	-f title \
	-o ${WORK_DIR}/lucene2seq_out \
	-xm sequential

# trim the useless header text from the file
${MAHOUT_HOME}/mahout seqdumper -i ${WORK_DIR}/lucene2seq_out/index | tail -n +5 | head -n -1 > ${DDR_DIR}/id2article.txt
#exit
#commented

# convert article names to database document ids
mkdir ${WORK_DIR}/ddr_seq
cd ${WIKICATEGORIES_REPO}/source_files &&
make -f makefile &&
./article2id > ${DDR_DIR}/idSuperCats.txt &&
cd ${ROOT_DIR}
#exit

# compile WikiTweet specific functions
echo "compiling wikitweet"
${MAVEN_HOME}/mvn -f ${WIKITWEET_REPO}/pom.xml package -DskipTests
mv ${WIKITWEET_REPO}/target/*.jar ${WORK_DIR}

# convert idSuperCats.txt to sequence file format
java -cp ${WORK_DIR}/wikitweet-0.1.jar com.wikitweet.tools.TextFile2SeqDriver \
	${DDR_DIR}/idSuperCats.txt \
	${WORK_DIR}/ddr_seq/idcats

# convert supercategories to vectors
java -cp ${WORK_DIR}/wikitweet-0.1.jar com.wikitweet.tools.Cat2SeqDriver \
	${WORK_DIR}/ddr_seq/idcats \
	${WORK_DIR}/ddr_seq/idcatsvectors
commout

# generate the key-value pairs in the format needed for mahout's naive Bayes
java -cp ${WORK_DIR}/wikitweet-0.1.jar com.wikitweet.tools.lucene_cats_combine \
	${WORK_DIR}/wiki-lucene-vec/tfidf-vectors/part-r-00000 \
	${WORK_DIR}/ddr_seq/idcatsvectors/part-m-00000 \
	${WORK_DIR}/ddr_seq/nb_input
exit

################################################################
# TODO: (1) Split the data right after pulling from solr
#       (2) Use output confusion matrix to observe Super Category distributions 
################################################################


<<commented3
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
commented3

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
