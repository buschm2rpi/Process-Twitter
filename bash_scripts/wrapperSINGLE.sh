#!/bin/bash

# setup evironmental variables that can be accessed by each Matlab sub-script
export DATASET=$1
export DATANAME=$2
export WEAK_CLASSIFIER=$3
export STRONG_CLASSIFIER=$4
export SUBGRAPHS=$5
export HTSET=$6

## specify important files and directories
#export DATAFILE=/local/home/student/petko/data_tgenome/$DATASET/data/hashtags.adopt.time.coded
#export TOPICSFILE=/local/home/student/mbusch/Twitter/HT_to_INDEX_conversion/hashtag.topics
#export ROOTDIR=/local/home/student/mbusch/Matlab/Data/$DATASET/$DATANAME/
#export EDGE_LIST=/local/home/student/mbusch/Matlab/Data/Matfiles/Network.mat
#export HT_MAP=/local/home/student/mbusch/Twitter/HT_to_INDEX_conversion/tagGroupsUnique-Fixed.txt

#export HTSET=all # 'all' or 'manual'

# specify important files and directories
export TOPROOTDIR=/local/home/student/mbusch/data_tgenome/$DATASET/data
export DATAFILE=$TOPROOTDIR/hashtags.$HTSET.adopt.time.coded
export TOPICSFILE=$TOPROOTDIR/hashtags.$HTSET.topics
export TOPICS_CODE=$TOPROOTDIR/hashtags.$HTSET.topics.README
export ROOTDIR=$TOPROOTDIR/$HTSET/$DATANAME/
export EDGE_LIST=/local/home/student/mbusch/Matlab/Data/Matfiles/Network.mat
export HT_MAP=$TOPROOTDIR/hashtags.$HTSET.list

# pass input into matlab
matlab -nojvm -nosplash -nodesktop -r "run ./processALL.m;quit;"