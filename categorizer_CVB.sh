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

# Pull the article term vectors off of solr
${MAHOUT_HOME}/mahout lucene2seq \
	-i ${INDEX_DIR} \
	-id id \
	-f text \
	-o ${WORK_DIR}/lucene2seq_out \
	-xm sequential

$ Convert the term vectors to mahout sparse format
${MAHOUT_HOME}/mahout seq2sparse \
	-i ${WORK_DIR}/lucene2seq_out \
	-o ${WORK_DIR}/seq2sparse_out \
	-wt tf \
	--maxDFPercent 85 \
	-nv
	
# This is needed to properly do a type conversion in mahout
${MAHOUT_HOME}/mahout rowid \
	-i ${WORK_DIR}/seq2sparse_out/tf-vectors/part-r-* \
	-o ${WORK_DIR}/matrix

#exit

#commented
<<ignore
# Single machine version of cvb (not yet working)
echo "running latent Dirichlet allocation"
${MAHOUT_HOME}/mahout cvb0_local \
	-i ${WORK_DIR}/matrix/matrix \
	-do ${WORK_DIR}/cvb_doc_out \
	-to ${WORK_DIR}/cvb_topic_out \
	-d ${WORK_DIR}/seq2sparse_out/dictionary.file-* \
	-m 2 \
	-top 4 
	-nt $(mahout seqdumper -i output/seq2sparse_out/dictionary.file-0 | tail -1 | awk '{print $2}') 
	
exit
ignore

# Run the CVB implementation of LDA
echo "running latent Dirichlet allocation"
${MAHOUT_HOME}/mahout cvb \
	-i ${WORK_DIR}/matrix/matrix \
	-o ${WORK_DIR}/cvb_out \
	-dict ${WORK_DIR}/wiki.seq \
	-mt ${WORK_DIR}/temp/models \
	-dt ${WORK_DIR}/temp/topics \
	-x 2 \
	-ow \
	-k 4 \
	-nt $(mahout seqdumper -i output/seq2sparse_out/dictionary.file-0 | tail -1 | awk '{print $2}') 

# View the topic distributions of each article
${MAHOUT_HOME}/mahout vectordump \
    -i ${WORK_DIR}/temp/topics/part-m-00000 \
    -o ${WORK_DIR}/cvb_out/vectordump \
    -vs 10 -p true \
    -d ${WORK_DIR}/seq2sparse_out/dictionary.file-* \
    -dt sequencefile -sort ${WORK_DIR}/temp/topics/part-m-00000 \
    && \
  cat ${WORK_DIR}/cvb_out/vectordump
	
