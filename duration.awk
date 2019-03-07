BEGIN{FS=":"}
/^Duration/ {
	hour = $2
	minute = $3
	second = $4
	print hour*60*60 + minute * 60 + second}
