#!/bin/bash

##==doing re-estimation for each gtf file=============#=========================#============================ 

#reference transcriptome (merged gtf file) 
merged_GTF_File="path/to/ref_gtf"


#paths which contain gtf and sorted bam files for all the plates
plate2Path="/data2/jzahiri/plate2/FinalResultsBackFrom_ASD_Server/FromJabba_gtf_sortedBam"
plate3Path="/data2/jzahiri/plate3/FinalResultsBackFrom_ASD_Server/FromJabba_gtf_sortedBam"
plate4Path="/data2/jzahiri/plate4/2019_02_01_ASD_R01_plate1"
plate5Path="/data2/jzahiri/plate5/2019_04_25_ASD_R01_plate2"
plate6Path="/data2/jzahiri/plate6/2019_08_28_ASD_plate6/"
plate7Path="/data2/jzahiri/plate7/2019_05_13_ASD_R01_plate3or5_brob_3/EC_05"
plate8Path="/data2/jzahiri/plate8/2019_07_08_ASD_plate3or6prob_4"
plate9Path="/data2/jzahiri/plate9/2019_08_23_ASD_plate5"
#declaring an array containing paths for all eight plates 
plate_Array_Path=($plate2Path $plate3Path $plate4Path  $plate5Path \
$plate6Path $plate7Path $plate8Path $plate9Path)
#=============#=====================#=================#=========================#============================
#doing re-estimation 
for path in "${plate_Array_Path[@]}"
do
        echo "$path"
        cd $path
        echo "next path"
        file_name_array=($(ls *sorted.bam))
        len=${#file_name_array[@]}
        for (( i=0; i<$len; i++))
        do
        	echo "re-estimation for file $i th: ${file_name_array[$i]}"
			final_gtf_file_name="${file_name_array[$i]}"
			final_gtf_file_name+="final.gtf"
			echo "the output file would be $final_gtf_file_name"
			stringtie -e -p 24 -G  $merged_GTF_File -o $final_gtf_file_name  ${file_name_array[$i]} 
        done 
done
#=============#=====================#=================#=========================#============================
##Constructing merged gtf file using string-tie

#setting the paths and creating the files if it is neccessary#==========================#====================#============= 
reference_annotation="/data/javad/Align/annotations/gencode.v36.annotation.gtf"
gtf_list_File="/data2/jzahiri/IntegratedResults/String_tie/Merged_gtf/total_eight_plates_gtf_file_list.txt"


#running stringtie in merge mode=======================#===================#=================#===========================
echo "stringtie merge mode"
stringtie --merge -p 25 -o stringtie_MERGED.gtf -G $reference_annotation $gtf_list_File

