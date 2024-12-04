samtools view -bq 1 unfiltered_file.bam > filtered_unique.bam

Samtools flagstat unfiltered_file.bam

Samtools flagstat filtered_file.bam

macs2 callpeak -t IP_mapping.bam -c control_mapping.bam -g hs -n NAME

bedtools intersect -v -a rep2_output_macs2_peaks.narrowPeak -b ENCFF356LFX.bed.gz > replicate2_no_blacklisted_peaks.narrowPeak wc -l file_no_blacklisted.narrowPeak

bedtools intersect -a replicate1_no_blacklisted_peaks.narrowPeak -b replicate2_no_blacklisted_peaks.narrowPeak -u | wc -l

bedtools intersect -a replicate1_no_blacklisted_peaks.narrowPeak -b merged_no_blacklisted_peaks.narrowPeak -u | wc -l

bedtools closest -a rep1_summits.bed -b rep2_summits.bed -d > closest_output.bed

awk '$NF >= 0 && $NF <= 100' closest_output.bed > filtered_output.bed

gunzip ENCFF410RJD.bed.gz

sort -k1,1 -k2,2n ENCFF410RJD.bed > sorted_ENCODE.bed

bedtools intersect -a rep1_output_macs2_peaks.narrowPeak -b rep2_output_macs2_peaks.narrowPeak -u > intersection_rep1and2_peak.narrowPeak

bedtools intersect -v -a intersection_rep1and2_peak.narrowPeak1 -b ENCFF356LFX.bed.gz > intersection_no_blacklisted_peaks.narrowPeak

bedtools jaccard -a merged_no_blacklisted_peaks.narrowPeak -b sorted_ENCODE.bed

awk 'BEGIN {OFS="\t"} {print $1, $2 + $10, $2 + $10 + 1, $4, $9}' intersection_1_2_no_blacklisted_peaks.narrowPeak > intersection_1_2_no_blacklisted_peaks.summits.bed

bedtools intersect -a merged_no_blacklisted_peaks.summit.bed -b K562_ChromHMM_15states.bed -wa -wb > chromatin_states_summit_merged_noBlacklisted.txt