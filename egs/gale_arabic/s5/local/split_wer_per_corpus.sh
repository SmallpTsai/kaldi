#!/bin/bash

# Report WER for reports and conversational
# Copyright 2014 QCRI (author: Ahmed Ali)
# Apache 2.0

if [ $# -ne 1 ]; then
   echo "Arguments should be the gale folder, see ../run.sh for example."
   exit 1;
fi

[ -f ./path.sh ] && . ./path.sh

#set -o pipefail -e

galeFolder=$(readlink -f $1)
symtab=./data/lang/words.txt

min_lmwt=7
max_lmwt=20

for dir in exp/*/*decode*; do
 for type in $(ls -1 local/test_list local/test.* | xargs -n1 basename); do
 #echo "Processing: $dir $type"
  rm -fr $dir/scoring_$type
  mkdir -p $dir/scoring_$type/log
  for x in $dir/scoring/*.tra $dir/scoring/test_filt.txt; do
    cat $x | grep -f local/$type > $dir/scoring_$type/$(basename $x)
  done

  utils/run.pl LMWT=$min_lmwt:$max_lmwt $dir/scoring_$type/log/score.LMWT.log \
     cat $dir/scoring_${type}/LMWT.tra \| \
      utils/int2sym.pl -f 2- $symtab \| sed 's:\<UNK\>::g' \| \
      compute-wer --text --mode=present \
       ark:$dir/scoring_${type}/test_filt.txt  ark,p:- ">&" $dir/wer_${type}_LMWT
done
done

time=$(date +"%Y-%m-%d-%H-%M-%S")
echo "#RESULTS splits generated by $USER at $time"

for type in $(ls -1 local/test_list local/test.* | xargs -n1 basename); do
 echo -e "\n# WER $type"
 for x in exp/*/*decode*; do
  grep WER $x/wer_${type}_* | utils/best_wer.sh;
 done | sort -n -k2
done




