#!/bin/bash

access_server() {
    read -p "Enter username: " username
    echo
    local server="159.149.160.7"
    ssh "$username@$server" <<EOF
    echo "Connected to server successfully"
    
    create_directories() {
        echo "inside create_directories"
        local -n numbers_array=\$1  # Reference to the numbers array
        local -n flags_array=\$2    # Reference to the flags array

        for ((i = 0; i < \${#numbers_array[@]}; i++)); do
            local number="\${numbers_array[i]}"  # Get the number at index i
            local flag="\${flags_array[i]}"      # Get the flag at index i
            mkdir -p "/home/$username/patient_\$number"        # Create the directory
        done
    }
    apply_function_to_array() {
        
        local -n numbers_array=\$1  # Reference to the numbers array
        local -n flags_array=\$2    # Reference to the flags array
        
        for ((i = 0; i < \${#numbers_array[@]}; i++)); do
            generate_filenames "\${numbers_array[i]}" "\${flags_array[i]}"
        done
    }
    generate_filenames() {
        local number=\$1  # Get the number
        local flag=\$2
        local path="/home/BCG2024_genomics_exam"  # Change this to your desired path
        local directory="/home/$username/patient_\$number"
        local father_filename="case\${number}_father"
        local mother_filename="case\${number}_mother"
        local child_filename="case\${number}_child"
 
        bowtie_function "\$father_filename" "\$number" "\$directory"
        bowtie_function "\$mother_filename" "\$number" "\$directory"
        bowtie_function "\$child_filename" "\$number" "\$directory"
        
        freebayes_function "\$father_filename" "\$mother_filename" "\$child_filename" "\$number" "\$directory"
        echo "number:"
        echo \$number
        grep_function1 "\$number" "\$directory"
        grep_function2 "\$number" "\$flag" "\$directory"
    }

    bowtie_function() {
        local filename=\$1
        local number=\$2
        local directory=\$3
        local path="/home/BCG2024_genomics_exam"  # Change this to your desired path
        local prefix="\${filename%.*}"              # Remove the extension
        if [[ "\$prefix" == *"mother"* ]]; then
            person="mother"
            relationship="'SM'"
        elif [[ "\$prefix" == *"father"* ]]; then
            person="father"
            relationship="'SF'"
        else
            relationship="'SC'"
            person="child"
        fi

        # Run bowtie2 command
        bowtie2 -U "\$path/\$filename.fq.gz" -p 8 -x "\$path/uni" --rg-id "\$relationship" --rg "SM:\$person"  | samtools view -Sb | samtools sort -o "\$directory/\$prefix.bam"
    }

    freebayes_function() {
        local father_bam=\$1
        local mother_bam=\$2
        local child_bam=\$3
        local number=\$4
        local directory=\$5
        local path="/home/BCG2024_genomics_exam"  # Change this to your desired path
        
        # Run freebayes command
        freebayes -f "\$path/universe.fasta" -m 20 -C 5 -Q 10 --min-coverage 10 "\$directory/\$mother_bam.bam" "\$directory/\$child_bam.bam" "\$directory/\$father_bam.bam" > "\$directory/case\$number.vcf"
    }
    
    grep_function1() {
        local number=\$1
        local directory=\$2
       
        # Run first grep command
        echo number
        grep "#" "\$directory/case\$number.vcf" > "\$directory/candilist\$number.vcf"
        grep "#" "\$directory/candilist\$number.vcf" > "\$directory/\${number}candilistTG.vcf"
    }

    grep_function2() {
        local number=\$1
        local flag=\$2
        local directory=\$3
       
        # Get the order of child, mother, and father from the header of the VCF file
        local header=\$(grep "#" "\$directory/case\$number.vcf" | tail -n 1)
        local order=\$(echo "\$header" | awk -F '\t' '{for (i=1; i<=NF; i++) if (\$i ~ /child/) child=i; if (\$i ~ /mother/) mother=i; if (\$i ~ /father/) father=i; print child, mother, father}')
        # Define the pattern based on the flag and the order of child, mother, and father
        local pattern=""

        if [[ "\$flag" == "AD" ]]; then
            if [[ "\$order" == *"1 2 3"* ]] || [[ "\$order" == *"1 3 2"* ]]; then
                pattern="0/1.*0/0.*0/0."
            elif [[ "\$order" == *"2 3 1"* ]] || [[ "\$order" == *"3 2 1"* ]]; then
                pattern="0/0.*0/0.*0/1."
            else 
                pattern="0/0.*0/1.*0/0."
            fi
        elif [[ "\$flag" == "AR" ]]; then
            if [[ "\$order" == *"1 2 3"* ]] || [[ "\$order" == *"1 3 2"* ]]; then
                pattern="1/1.*0/1.*0/1."
            elif [[ "\$order" == *"2 3 1"* ]] || [[ "\$order" == *"3 2 1"* ]]; then
                pattern="0/1.*0/1.*1/1."
            else 
                pattern="0/1.*1/1.*0/1."
            fi
        fi

        # Run second grep command
        grep "\$pattern" "\$directory/case\$number.vcf" >> "\$directory/candilist\$number.vcf"
        
        # Run bedtools intersect command
        bedtools intersect -a "\$directory/candilist\$number.vcf" -b "\$path/exons16Padded_sorted.bed" -u >> "\$directory/\${number}candilistTG.vcf"
    }
  
    numbers=(613 676 688 627 607 657 746 696 715 655)
    flags=(AD AD AR AD AR AD AR AD AD AD)
    create_directories numbers flags
    apply_function_to_array numbers flags
    
EOF
    echo "Session terminated"
}

echo "Script started"
access_server
echo "Script completed"




