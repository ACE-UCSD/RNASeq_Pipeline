#!/bin/bash
##Doing preprocessing/ calling / filteratoin/ annotation for variants in RNA-Seq data

#I got errors running the original bash script code so I'm trying to debug it. The main errors seem to be related to the file and path!
#SO, I'm goign to 
###########################################################################################################################################################################
#specifing the reference files/folders
#to be completed ...
RefGen4GATK="/data2/jzahiri/RefFiles/RefGenome/GATK/Homo_sapiens_assembly38.fasta"
DBsnp138="/data2/jzahiri/RefFiles/VCF/Homo_sapiens_assembly38.dbsnp138.vcf"
GATK_Path="/home/jzahiri/gatk"
AnnovarPath="/home/jzahiri/annovar"
#paths which contain sorted bam files for all the plates
plate2Path="/data2/jzahiri/plate2/FinalResultsBackFrom_ASD_Server/FromJabba_gtf_sortedBam"
plate3Path="/data2/jzahiri/plate3/FinalResultsBackFrom_ASD_Server/FromJabba_gtf_sortedBam"
plate4Path="/data2/jzahiri/plate4/2019_02_01_ASD_R01_plate1"
plate5Path="/data2/jzahiri/plate5/2019_04_25_ASD_R01_plate2"
plate6Path="/data2/jzahiri/plate6/2019_08_28_ASD_plate6/"
plate7Path="/data2/jzahiri/plate7/2019_05_13_ASD_R01_plate3or5_brob_3/EC_05"
plate8Path="/data2/jzahiri/plate8/2019_07_08_ASD_plate3or6prob_4"
plate9Path="/data2/jzahiri/plate9/2019_08_23_ASD_plate5"
# declaring an array containing paths for all eight plates 
plate_Array_Path=($plate2Path $plate3Path $plate4Path  $plate5Path \
 $plate6Path $plate7Path $plate8Path $plate9Path)
# 4.14.2022:
# plate_Array_Path=($plate6Path $plate7Path $plate8Path $plate9Path)
###########################################################################################################################################################################
#doing re-estimation 
for path in "${plate_Array_Path[@]}"
do
        echo "NEW PATH!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "$path"
        cd $path
        #echo "next path"
        file_name_array=($(ls *sorted.bam))
        #in each iteration i is the index for a sorted bam file 
        len=${#file_name_array[@]}
        for (( i=0; i<$len; i++))
        do
            echo "NEW FILE"
            echo "##################################################################################"
        ###########################################################################################################################################################
        ##Preprocessing======================================================================================================
        #MarkDuplicates==========================================
            echo "##################################################################################"
            echo "file : ${file_name_array[$i]}"
            MarkDupFileName=${file_name_array[$i]}                
            MarkDupFileName+=".MarkDup.bam"
            MarkDupMetricFileName=${file_name_array[$i]}
            MarkDupMetricFileName+=".Metric.txt"
            PicardCommandLine MarkDuplicates\
             I=${file_name_array[$i]} \
             O="$MarkDupFileName" \
             M="$MarkDupMetricFileName"
            echo "MarkDupFileName:" 
            echo "$MarkDupFileName" 
            echo "MarkDupMetricFileName:" 
            echo "$MarkDupMetricFileName" 
            #SplitNCigarReads==========================================
            echo "##################################################################################"
            SplitNCigFileName=${file_name_array[$i]}
            SplitNCigFileName+=".SplitNCig.bam"
            /home/jzahiri/gatk/gatk SplitNCigarReads \
             -R "$RefGen4GATK" \
             -I "$MarkDupFileName" \
             -O "$SplitNCigFileName"
            echo "SplitNCigFileName:"
            echo "$SplitNCigFileName"
            #AddOrReplaceReadGroups==========================================
            echo "##################################################################################"
            AddOrReplaceReadGroupsFileName=${file_name_array[$i]}
            AddOrReplaceReadGroupsFileName+="AddeddGroup.bam"
            picard-tools AddOrReplaceReadGroups  \
                I="$SplitNCigFileName"\
                O="$AddOrReplaceReadGroupsFileName" \
                RGID=1 RGLB=mylib RGPL=illumina RGPU=unit1 RGSM=100
            echo "AddOrReplaceReadGroupsFileName:" 
            echo "$AddOrReplaceReadGroupsFileName" 
            #BaseRecalibration==========================================
            echo "##################################################################################"
            BaseRecalFileName=${file_name_array[$i]}  
            BaseRecalFileName+=".BaseRecal.bam"    
            RecalibTableFileName=${file_name_array[$i]}        
            RecalibTableFileName+="Recalib.table"
	    /home/jzahiri/gatk/gatk BaseRecalibrator \
             -R "$RefGen4GATK"\
             -I "$AddOrReplaceReadGroupsFileName" \
             --known-sites "$DBsnp138" \
             -O "$RecalibTableFileName"
             #applying BSQR
            /home/jzahiri/gatk/gatk ApplyBQSR \
                -R "$RefGen4GATK" \
                -I "$AddOrReplaceReadGroupsFileName" \
                --bqsr-recal-file "$RecalibTableFileName" \
                -O "$BaseRecalFileName"
            echo "BaseRecalFileName:" 
            echo "$BaseRecalFileName"
            ########################################################################################################################################################### 
            ##Variant Calling & Filtering ======================================================================================================
            #HaplotypeCalling==========================================
            echo "##################################################################################"
            FirstVcfFileName=${file_name_array[$i]} 
            FirstVcfFileName+=".HapCaller.vcf.gz"
            /home/jzahiri/gatk/gatk --java-options "-Xmx12g" HaplotypeCaller \
            -R  "$RefGen4GATK" \
            -I "$BaseRecalFileName"  -O "$FirstVcfFileName"
            #Filteration==========================================
            echo "##################################################################################"
            FilterFlagVcfFileName=${file_name_array[$i]} 
            FilterFlagVcfFileName+=".FilterFlag.vcf.gz"
            /home/jzahiri/gatk/gatk VariantFiltration \
            -R  "$RefGen4GATK" \
            -V "$FirstVcfFileName" -O "$FilterFlagVcfFileName"\
            --cluster-size 3 -window 35 -filter "QD < 2.0" --filter-name "QD2" \
            -filter "QUAL < 30.0" --filter-name "QUAL30"     -filter "SOR > 3.0" --filter-name "SOR3" \
            -filter "FS > 60.0" --filter-name "FS60"  -filter "MQ < 40.0" --filter-name "MQ40" \
            -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
            -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
            --verbosity ERROR
            echo "FirstVcfFileName:" 
            echo "$FirstVcfFileName"

            ###########################################################################################################################################################            
            ##Varian annotation by ANNOVAR======================================================================================================
            #file conversion 
            echo "##################################################################################"
            VariantClledFileAnnovarFormatFileName=${file_name_array[$i]}
            VariantClledFileAnnovarFormatFileName+=".AnnovarFormat"
            perl "$AnnovarPath"/convert2annovar.pl -format vcf4  \
            --includeinfo --keepindelref "$FilterFlagVcfFileName" --outfile "$VariantClledFileAnnovarFormatFileName"
            #Variant annotation 
            FinalCSV_VariantCallingFileName=${file_name_array[$i]} 
            FinalCSV_VariantCallingFileName+="FinalAnnovarGenerated.csv"
            perl "$AnnovarPath"/table_annovar.pl "$VariantClledFileAnnovarFormatFileName" \
              /data2/jzahiri/RefFiles/Annovar/ -buildver hg38 \
              -out "$FinalCSV_VariantCallingFileName"\
              --protocol knownGene,refGene,clinvar_20210501  -operation g,g,f  -nastring .  -polish --thread 5 --csvout --gff3dbfile /data2/jzahiri/RefFiles/Annovar/GRCh38_latest_genomic.gff --remove --otherinfo 
            echo "VariantClledFileAnnovarFormatFileName:" 
            echo "$VariantClledFileAnnovarFormatFileName"
            ########################################################################################################################################################### 
            #Removing intermed files (except last two: final Annovar and happlotypecaller files)
            rm "$MarkDupFileName"
            rm "$SplitNCigFileName"
            rm "$AddOrReplaceReadGroupsFileName"
            rm "$BaseRecalFileName"
            rm "$MarkDupMetricFileName"
            rm "$FilterFlagVcfFileName"
        done 
done