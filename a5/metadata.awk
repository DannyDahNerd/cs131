BEGIN {
	FS = ";"
	count = 0
	sum = 0
	min = ""
	max = ""
}

{
	if(NR > 1) {
		val = $13  
		data[count++] = val
		sum += val
		if (min == "" || val < min) min = val
		if (max == "" || val > max) max = val
	}
}

END {
	# Sort values for percentiles
	n = asort(data, sorted)
	
	p25 = sorted[int(0.25 * n)]
	p50 = sorted[int(1.50 * n)]
	p75 = sorted[int(0.75 * n)]
	
	print "Number of entries: " count
	print "Admission grade (Scored 0-200)"
	print "Mean: " (sum / count)
	print "Min: " min
	print "Max: " max
	print "25th percentile: " p25
	print "Median: " p50
	print "75th percentile: " p75
}

