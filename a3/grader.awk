BEGIN {
	#set field sep, as well as vars for highest/lowest student and score
	FS =","
	highest_student = ""
	highest_score = 0
	lowest_student = ""
	lowest_score = 301

}
{
	#skip the header
	if (NR >1) {
		#students array, match student ID to student name
		students[$1] = $2

		# "2D" array, matching student ID and string "sum" to the sum of the student's grade
		grade_info[$1, "sum"] = $3 + $4 + $5

		#logic for setting highest and lowest score and student
		if(grade_info[$1, "sum"] > highest_score) {
			highest_score = grade_info[$1, "sum"]
			highest_student = $2
		}
		if(grade_info[$1, "sum"] < lowest_score) {
			lowest_score = grade_info[$1, "sum"]
			lowest_student = $2
		}

		# matches student ID and string "avg" to the average of the grades, called separately
		grade_info[$1, "avg"] = AVG_GRADE($1)

		# logic mapping id and "pass" to either PASS or FAIL
		if(grade_info[$1, "avg"] >= 70) {
			grade_info[$1, "pass"] = "PASS"
		}
		else {
			grade_info[$1, "pass"] = "FAIL"
		}
	}

}
END {
	#for each student, print the sum average and pass/fail
	for(student in students) {
		print students[student], grade_info[student, "sum"], grade_info[student, "avg"], grade_info[student, "pass"] 
	}

	#print lowest/highest student and score
	print "highest student: ", highest_student, highest_score
	print "lowest student: ", lowest_student, lowest_score
}

#function to calculate average
function AVG_GRADE(student) {
	return (grade_info[student, "sum"]/3)
}
