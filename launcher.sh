#variables
inFile=$1
outFile=$2
replaceTroop=$3
replaceTroopSwipe=$4
isServer=$5
manData=$6
width=$7
height=$8
orientation=$9

if [ "$inFile" == "$outFile" ]; then
	echo "Error! Input file and output file can´t be the same"
	exit 1
fi

awk -v outFile=$outFile -v manData=$manMeta -v isServer=$isServer -v width=$width -v height=$height -v orientation=$orientation -v replaceTroop=$replaceTroop -v replaceTroopSwipe=$replaceTroopSwipe -f scriptParser.awk $inFile