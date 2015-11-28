#variables
inFile=$1
outFile=$2
manMeta=$3
width=$4
height=$5
orientation=$6
replaceTroop=$7
replaceSwipe=$8
isServer=$9

if [ "$inFile" == "$outFile" ]; then
	echo "Error! Input file and output file can´t be the same"
	exit 1
fi
# human
if [ -z "$isServer" ]; then
	echo "You are a human!"
	awk -v outFile=$outFile -v manMeta=$manMeta -v isServer=$isServer -v width=$width -v height=$height -v orientation=$orientation -f scriptParser.awk $inFile
fi
#server (actually there is no difference, im not sure about that yet)
if [ -n "$isServer" ]; then
	if [ "$isServer"  -eq 1 ]; then
		echo "You aren´t human!"
		awk -v outFile=$outFile -v manMeta=$manMeta -v isServer=$isServer -v width=$width -v height=$height -v orientation=$orientation -f scriptParser.awk $inFile
    elif [ "$isServer" -eq 0 ]; then
        echo "You are a human!"
        awk -v outFile=$outFile -v manMeta=$manMeta -v isServer=$isServer -v width=$width -v height=$height -v orientation=$orientation -f scriptParser.awk $inFile
    fi
fi