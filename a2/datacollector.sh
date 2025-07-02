#!/bin/bash

echo "Enter the URL of the dataset:"
read url

#make a folder to store everything in for easy clean up
mkdir data
cd data

filename=$(basename "$url")
#use curl to extract it
curl -O "$url"

#unzip if zipped
if [[ "$filename" == *.zip ]]; then
        unzip "$filename"
        #-Z1 means we list each file 1 per line
        #grep then only matches the pattern to .csv
        csvfiles=$(unzip -Z1 "$filename" | grep '\.csv$')
else
        csvfiles="$filename"
fi

#for each csvfile in the zip (or just 1 if it was the single csv file)
for csvfile in $csvfiles; do
	# get header (first line) and clean it
        header=$(head -n1 "$csvfile")


        #replace all " with blank (for clean head)
        cleanheader=$(echo "$header" | sed 's/"//g')

        #detect delimiter
	#use -q quiet option to not clutter terminal
        if echo "$cleanheader" | grep -q ";" ; then
                delim=";"
        elif echo"$cleanheader" | grep -q "\t"; then
                delim="\t"
        else
                delim=","
        fi

        #get all features
	#take the header, split by the delim, and essentially split each feature into a separate line 
	#to store into features array
        features=($(echo "$cleanheader" | awk -F"$delim" '{for(i=1; i<=NF; i++) print $i}'))

        #prints all features while also keeping track of which one is the longest       
        maxlen=0
        echo "Detected features in $csvfile:"
        for i in "${!features[@]}"; do
                len=${#features[$i]}
                if (( len > maxlen )); then
                        maxlen=$len
                fi
                #i indexes at 0, want to start at 1
                echo "$((i+1)). ${features[$i]}"
        done

	#prompt for columns
	echo "Enter the column indicies of numerical columns separated by space:"
	read cols
	# takes cols and reads it into an array called numcols
	numcols=($cols)

        #helps format the dash to match the features
        #creates a buunch of spaces to max maxlen
        #replaces all spaces with a dash
        feature_dashes=$(printf '%*s' "$maxlen" "" | sed 's/ /-/g')

        #create summary file as well as header
        summaryfile="summ_${csvfile%.csv}.md"
        echo "# Feature Summary for $csvfile" > "$summaryfile"
        echo "" >> "$summaryfile"
        echo "## Feature Index and Names" >> "$summaryfile"

        #must use @ to iterate over every element indivudally
        for i in "${!features[@]}"; do
                echo "$((i+1)). ${features[$i]}" >> "$summaryfile"
        done

        echo "" >> "$summaryfile"
        echo "## Statistics (Numerical Features)" >> "$summaryfile"
        printf "| Index | %-*s | Min     | Max     | Mean    | StdDev  |\n" $maxlen "Feature"  >> "$summaryfile"
        printf "|-------|%s--|---------|---------|---------|---------|\n" "$feature_dashes" >> "$summaryfile"
        for col in "${numcols[@]}"; do
                index=$((col - 1))
                colname=${features[$index]}
                colname=$(echo "$colname" | sed 's/"//g')
                values=$(tail +2 "$csvfile" | cut -d"$delim" -f"$col" | sed '/^$/d')
                min=$(echo "$values" | awk 'NR==1 {min=$1} $1<min{min=$1} END{print min}')
                max=$(echo "$values" | awk 'NR==1 {max=$1} $1>max{max=$1} END{print max}')
                mean=$(echo "$values" | awk '{sum+=$1} END{if (NR>0) print sum/NR; else print 0}')
                std=$(echo "$values" | awk -v mean="$mean" '{sumsq+=($1-mean)^2} END{if (NR>0) print sqrt(sumsq/NR); else print 0}')
                printf "| %-5s | %-*s | %-7.2f | %-7.2f | %-7.3f | %-7.3f |\n" "$col" $maxlen "$colname" "$min" "$max" "$mean" "$std" >> "$summaryfile"
        done
        echo "Generated $summaryfile"
done
