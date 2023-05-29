#!/bin/bash


current_wd="/data2/jzahiri/plate4/2019_02_01_ASD_R01_plate1"
cd  $current_wd

#creating a file for computing run time
touch hisatIndex_time_log.txt 
echo "start">>hisatIndex_time_log.txt
echo  $start>>hisatIndex_time_log.txt
echo "==================new run with trimming========================">> new_hisat_out_2.txt

#source_DATA_PATH  is a sim link to the source path of the .gz files

file_name_array=($(ls source_DATA_PATH/*.gz))

genome_path="/data/javad/Align/grch38/newRefIndex_from_NCBI_02_26_2021/GCA_000001405.15_GRCh38_full_plus_hs38d1_analysis_set"
#alig_path="/data/javad/Align/"
annotaion_file="/data/javad/Align/annotations/gencode.v36.annotation.gtf"
#=================#=================#=================#=================#=================
#getting the length of the file_name_arrayay (which is the number of .gz files)
len=${#file_name_array[@]}

#!! set i=0 and j=1
#in each iteration two files will be used for mapping (the RNA-seq data are PE)
for (( i=0, j=i+1; i<len; i++, i++, j++, j++))
do
#Copy the fastq files=================#=================#=================#=================#=========
                start=`date +%s`
                echo '============================================================================'
                #${file_name_array[$i]} would be like this "plate2Data/Undetermined_S0_L004_R2_001.fastq.gz"
                echo "file: ${file_name_array[$i]}" 
                echo "try to copy files"
                echo "${file_name_array[$i]}"
                cp "${file_name_array[$i]}" $current_wd&
                echo "${file_name_array[$j]}"
                cp "${file_name_array[$j]}" $current_wd #                               
                end=`date +%s`
                runtime=$((end-start))
                echo "copy time:"
                echo $runtime>>hisatIndex_time_log.txt
                echo $runtime
#Unzipping=================#=================#=================#=================#=========
                #extracting the file name from the path
                echo "copping was finished"
                start=`date +%s`
                #seperating using "/" as delim and converting to an array "ARR"
                IFS='/'; read -ra ADDR <<< "${file_name_array[$i]}"     
                #the last ARR element is the file name 
                zip_fastq_file_nameR1=${ADDR[-1]}
                IFS='/'; read -ra ADDR <<< "${file_name_array[$j]}"     
                zip_fastq_file_nameR2=${ADDR[-1]}               

                #unzipping the copied file
                echo "the first grabed file name for unzipping"
                echo "$zip_fastq_file_nameR1"
                gunzip "$zip_fastq_file_nameR1"&
                echo "the second grabed file name for unzipping"
                echo "$zip_fastq_file_nameR2"
                gunzip "$zip_fastq_file_nameR2" 
                end=`date +%s`
                runtime=$((end-start))
                echo "unzipping:">>hisatIndex_time_log.txt
                echo $runtime>>hisatIndex_time_log.txt
                echo $runtime
#Extracting the files' base names=================#=================#=================#=================#=========
                #grabbing base names of the current pair of files (base name means file name without extension)
                # period "." was used as the seperator  
                IFS='.'; read -ra ADDR <<< "$zip_fastq_file_nameR1"
                fileR1_base_name=${ADDR[0]}
                IFS='.'; read -ra ADDR <<< "$zip_fastq_file_nameR2"
                fileR2_base_name=${ADDR[0]}
                echo  "1st basename file name for furthure anlysis: $fileR1_base_name"
                echo  "2nd basename file name for furthure anlysis: $fileR2_base_name"                
#HISAT2=================#=================#=================#=====================
                #Alignment using hisat2

                echo "running hisat2 on $i th file"


                fastq_file1=$fileR1_base_name
                fastq_file1+=".fastq"
                echo "-1 $fastq_file1"

                fastq_file2=$fileR2_base_name
                fastq_file2+=".fastq"
                echo "-2 $fastq_file2"
                
                sam_file_name=$fileR1_base_name
                sam_file_name+="_new.sam"
                echo "-S $sam_file_name"
                
                #If you want to trimm : --trim5 int
                hisat2  --trim5 9 -p 22 -k 2 -q -x "$genome_path" -1 "$fastq_file1" -2 "$fastq_file2" -S "$sam_file_name" 2>$
                end=`date +%s`
                runtime=$((end-start))
                echo "hisat2:">>hisatIndex_time_log.txt
                echo $runtime>>hisatIndex_time_log.txt
                echo "hisat2:"
                echo $runtime
                rm "$fastq_file1"&
                rm "$fastq_file2"&
                
#SAMTOOLS=================#=================#=================#===================

                echo "running samtools sam2bam on $i th file"
                bam_file_name=$fileR1_base_name
                bam_file_name+="_new.bam"
                samtools view -S -b -@ 20 "$sam_file_name" > "$bam_file_name"
                rm  "$sam_file_name"

                echo "running samtools sorting bam $i th file"
                sorted_bam_file_name=$fileR1_base_name
                sorted_bam_file_name+="_newsorted.bam"
                samtools sort -@ 20 "$bam_file_name" -o "$sorted_bam_file_name"
                end=`date +%s`
                runtime=$((end-start))
                echo "samtools:">>hisatIndex_time_log.txt
                echo $runtime>>hisatIndex_time_log.txt
                echo $runtime
#STRINGTIE#1/2=================#=================#=================#==============
                echo "running stringtie on $i th file"
                gtf_file_name=$fileR1_base_name
                gtf_file_name+="_new.gtf"
                stringtie -p 10 -G "$annotaion_file" -o  "$gtf_file_name"  -l "$fileR1_base_name" "$sorted_bam_file_name" 2>$
                
                echo "removing bam file"
                rm "$bam_file_name"

                end=`date +%s`
                runtime=$((end-start))
                echo "stringtie:">>hisatIndex_time_log.txt
                echo $runtime>>hisatIndex_time_log.txt
                echo "stringtie:"
                echo $runtime

done