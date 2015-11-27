#variables
inFile=$1
outFile=$2
isServer=$3
replaceTroop=$4
replaceSwipe=$5
manMeta=$6
width=$7
height=$8
orientation=$9

if [ "$inFile" == "$outFile" ]; then
	echo "Error! Input file and output file can´t be the same"
	exit 1
fi
# human
if [ -z "$3" -o "$3" -eq 0 ]; then
	echo "You are a human!"
	awk -v manMeta=$manMeta -v isServer=$isServer -v width=$width -v height=$height -v orientation=$orientation -f scriptParser.awk $inFile
fi
#server (actually there is no difference, im not sure about that yet)
if [ -n "$3" ]; then
	if [ "$isServer"  -eq 1 ]; then
		echo "You aren´t human!"
		awk -v manMeta=$manMeta -v isServer=$isServer -v width=$width -v height=$height -v orientation=$orientation -f scriptParser.awk $inFile
	fi
fi