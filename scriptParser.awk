#extracts the rotation and orientation out of script
function getMeta()
	{#function start
	while ( (getline extLine < filename) > 0) {
		#try get Resolution from "adapt..."
		if( match(extLine, /^adaptResolution\(/) != 0 && resFound != 1) {
			#get width, height
			split(extLine, metaTMP, /\(|, |\)/)
			width=metaTMP[2]
			height=metaTMP[3]
			if (width ~ /^[0-9]{3,4}$/ && height ~ /^[0-9]{3,4}$/) {
				resFound=1
			}
			}
		#try get Resolution from "#SCREEN_RE..."
		else if( match(extLine, /^SCREEN_RESOLUTION="/) != 0 && resFound != 1) {
			#get width, height
			split(extLine, metaTMP, /"|x/)
			width=metaTMP[2]
			height=metaTMP[3]
			if (width ~ /^[0-9]{3,4}$/ && height ~ /^[0-9]{3,4}$/) {
				resFound=1
			}
		}
		else if( match(extLine, /^adaptOrientation\(/) != 0 && oriFound != 1) {
		split(extLine, metaTMP, /_|\)/)
		orientation=metaTMP[3]
		if(orientation == "LEFT" || orientation == "RIGHT") {
			oriFound=1
		}
		}
	}#end while
	#close the input file again
	close(filename)
	}#end function



#check resolution, "output"=array
#1=wrong; 0=true
function checkRes() {#start function
    #check both
    if (width !~ /^[0-9]{3,4}$/ && height !~ /^[0-9]{3,4}$/) {
        resWrong["all"]=1
        if(isServer == 1)exit 1
    }
    else if(width ~ /^[0-9]{3,4}$/ || height ~ /^[0-9]{3,4}$/) {
        resWrong["all"]=0
    }
    if(resWrong["all"] != 1){

        #width in detail
        if(width ~ /^[0-9]{3,4}$/) {
            resWrong["width"]=0
        }
        else {
            resWrong["width"]=1
            if(isServer == 1)exit 1
        }

        #height in detail
        if(height ~ /^[0-9]{3,4}$/) {
            resWrong["height"]=0
        }
        else {
            resWrong["height"]=1
            if(isServer == 1)exit 1
        }
    }
}#end function



#check orientation
#1=wrong; 0=true
function checkOri() {
    if(orientation != "LEFT") {
        if(orientation != "RIGHT") {
            oriWrong=1
            if(isServer == 1)exit 1
        }
        else {
            oriWrong=0
        }
    }
    else {
        oriWrong=0
    }
}#end function

##sadly exit this script
function exitSad() {
    print "Something went wrong. :(\nExiting..."
    exit 1
}



#checks if everything´s cool with the meta data
function checkMeta() {
    #run checks:
    checkOri()
    checkRes()

	#check orientration
    while(oriWrong == 1) {
        print "Error! The orientation is incorrect, please enter a valid one.\nLEFT or RIGHT (case sensitive) or Type \"exit\" to exit:"
        getline userIn < "-"
        if(userIn == "exit"){
            exitSad()
        }
        orientation=userIn
        checkOri()
    }

    #check resolution
    while(resWrong["all"] == 1 || resWrong["width"] == 1 || resWrong["height"] == 1) {
        if (resWrong["all"] == 1) {
            print "Error! The resolution is incorrect (width and height). Please enter them correctly\nor Type \"exit\" to exit:"
            print "Enter the width:"
            getline userIn < "-"
            if(userIn == "exit"){
                exitSad()
            }
            width=userIn

            print "Enter the height:"
            getline userIn < "-"
            if(userIn == "exit"){
                exitSad()
            }
            height=userIn
            checkRes()
        }

        if (resWrong["width"] == 1) {
            print "Error! The resolution is incorrect (width). Please enter it correctly\nor Type \"exit\" to exit:"
            print "Enter the width:"
            getline userIn < "-"
            if(userIn == "exit"){
                exitSad()
            }
            width=userIn
            checkRes()
        }

        if (resWrong["height"] == 1) {
            print "Error! The resolution is incorrect (height). Please enter it correctly\nor Type \"exit\" to exit:"
            print "Enter the width:"
            getline userIn < "-"
            if(userIn == "exit"){
                exitSad()
            }
            height=userIn
            checkRes()
        }
    }
}#end input functions



##parsing functions

#print without empty fields
function finalPrint() {
    printLineCount=1
    #clear file, might not be empty...
    print "" > outFile
    while( printLineCount <= NF ) {
        if( $printLineCount == "" && $(printLineCount+1) == "") {
            print $printLineCount >> outFile
            printLineCount=printLineCount+2
        }
        else {
        print $printLineCount >> outFile
        printLineCount=printLineCount+1
        }
    }

}

#function fixBlocks() {
#    tmpCounter=1
#    while( tmpCounter <= NF ) {
#        #find TouchDown
#        if( $tmpCounter ~ /touchDown\(/ && $(tmpCounter+1) == "" ) {
#            $(tmpCounter+1) = $tmpCounter
#            $tmpCounter = ""
#        }
#        else {
#            tmpCounter=tmpCounter+1
#        }
#    }
#
#}

#gets ID of a touchDown, returns the ID, first param is string
#of touchDown
function getTDownID(tDownID) {
    split(tDownID, tmpArray, "[\(,]")
    return tmpArray[2]
}

#finds end and beginning of first/next Block
function findBlock() {
    if(cBlockEnd > 1) {
        tmpCounter = cBlockEnd+1
    }
    else {
        tmpCounter = 1
    }


    #find start of block
    while( tmpCounter <= NF && cBlockStartFound != 1 ) {
        if( $tmpCounter ~ /touchDown\(/ ) {
            cBlockStart = tmpCounter
            cBlockStartFound = 1
            cBlockID = getTDownID($cBlockStart)
            tmpRegex = sprintf("touchUp\\\((%s)", cBlockID)
        }
        tmpCounter = tmpCounter+1
    }


    #find end of block
    while ( tmpCounter <= NF && cBlockEndFound != 1 ) {
        #print nestTDownCounter
        #if touchUp is found and nestTDownCounter == 0, finsihed
        if( $tmpCounter ~ tmpRegex && nestTDownCounter == 0 ){
            cBlockEnd = tmpCounter
            cBlockEndFound = 1
        }
        #if a new tDown is found, add id to tmpRegex
        else if( $tmpCounter ~ /touchDown\(/ ) {
            #get ID from TDown found
            cBlockID = getTDownID($tmpCounter)
            sub(/\(\(/, "&"cBlockID"|", tmpRegex)
            nestTDownCounter = nestTDownCounter+1
        }
        #if touchUp is found but nested > 0, reduce regex by that id
        else if( $tmpCounter ~ tmpRegex && nestTDownCounter > 0 ) {
            cBlockIDRemove = getTDownID( $tmpCounter )
            toFind = sprintf("(\\|%s|\\|%s)", cBlockIDRemove, cBlockIDRemove)
            sub(toFind, "", tmpRegex)
            nestTDownCounter = nestTDownCounter-1
        }
        tmpCounter = tmpCounter+1
    }
    #for next loop
    cBlockEndFound = 0

    #expand block te the start of next one
    while( tmpCounter <= NF && cBlockEndFound != 1 ) {
        #print "hallo"
        if( $tmpCounter ~ /touchDown\(/ ) {
            cBlockEnd = tmpCounter-1
            cBlockEndFound = 1
        }
        tmpCounter = tmpCounter+1
    }
    cBlockEndFound = 0


    if( cBlockStartFound == 0 ) {
        return "EOF"
    }

    #debugg printn
#print "FOUND BEGINNING: " cBlockStart
#   print "FOUND END at: "cBlockEnd

    cBlockStartFound = 0
    cBlockEndFound = 0
}

#get xCoo of a Command and return it
function getXCoo(aTCommand) {
    split(aTCommand, tmpArray, / |,|\)/)
    return tmpArray[3]
}

#get yCoo of a Command and return it
function getYCoo(aTCommand) {
    split(aTCommand, tmpArray, / |,|\)/)
    return tmpArray[5]
}

#tDown Analysis, returns a comment string
function tDownAnalysis(tDownLine) {
    #get Y and X coo
    tDAnalysisX = getXCoo(tDownLine)
    tDAnalysisY = getYCoo(tDownLine)

    tDAnalysisX += 0
    #check if a troop select
    print "hello"
    print tDownLine
    if( isTroopbar(tDownLine) == 1 ) {
        print "BYE"
        #check what slot
        for( n = 1; n <= 12; n++ ) {
            #print "checking if Y="tDAnalysisY"is in slot "n" which is between "FiBSlot[n]"and "FiBSlot[n]

            #conv to ints -.-
            tDAnalysisY += 0
            FiBSlot[n] += 0
            FiESlot[n] += 0
            if( tDAnalysisY >= FiBSlot[n] && tDAnalysisY <= FiESlot[n] ) {
                returnValue = sprintf ("--select(\"slot%s\");", n)
                return returnValue
            }
        }
    }
    return ""
}

#calculate Coo constants
function calcCooCs() {
    #xCoo
    xCoo = sprintf("%.0f", width*0.13021)

    #LeBeginning of slots
    LeBSlot[1] = sprintf("%.0f", height*0.00000)
    LeBSlot[2] = sprintf("%.0f", height*0.08887)
    LeBSlot[3] = sprintf("%.0f", height*0.17188)
    LeBSlot[4] = sprintf("%.0f", height*0.25488)
    LeBSlot[5] = sprintf("%.0f", height*0.33887)
    LeBSlot[6] = sprintf("%.0f", height*0.42383)
    LeBSlot[7] = sprintf("%.0f", height*0.50879)
    LeBSlot[8] = sprintf("%.0f", height*0.59277)
    LeBSlot[9] = sprintf("%.0f", height*0.67773)
    LeBSlot[10] = sprintf("%.0f", height*0.76074)
    LeBSlot[11] = sprintf("%.0f", height*0.84473)
    LeBSlot[12] = sprintf("%.0f", height*0.92969)

    #end of slots
    LeESlot[1] = sprintf("%.0f", height*0.08789)
    LeESlot[2] = sprintf("%.0f", height*0.17090)
    LeESlot[3] = sprintf("%.0f", height*0.25391)
    LeESlot[4] = sprintf("%.0f", height*0.33789)
    LeESlot[5] = sprintf("%.0f", height*0.42285)
    LeESlot[6] = sprintf("%.0f", height*0.50781)
    LeESlot[7] = sprintf("%.0f", height*0.59180)
    LeESlot[8] = sprintf("%.0f", height*0.67676)
    LeESlot[9] = sprintf("%.0f", height*0.75977)
    LeESlot[10] = sprintf("%.0f", height*0.84375)
    LeESlot[11] = sprintf("%.0f", height*0.92871)
    LeESlot[12] = sprintf("%.0f", height*1.00000)


    if( orientation == "RIGHT" ) {
        print recalc
        #redefine slots (1=12 2=11...)
        tmpCounter = 13
        for(n = 1; n <= 12; n++){
            tmpCounter--
            #tmp Save of Coos
            RiBSlot[n] = LeBSlot[tmpCounter]
            RiESlot[n] = LeESlot[tmpCounter]
        }
        #finish up
        for(n = 1; n <= 12; n++){
            FiBSlot[n] = RiBSlot[n]
            FiESlot[n] = RiESlot[n]
        }
        xCoo = width-xCoo
    }
    else {
        for(n = 1; n <= 12; n++){
            FiBSlot[n] = LeBSlot[n]
            FiESlot[n] = LeESlot[n]
        }
    }
#xCoo = toNumber(xCoo)
 }

#checks the current type of block, return: "noswipe", "troopswipe", "swipe"
function checkBlock() {
    tmpCounter = cBlockStart
    for( i = cBlockStart; i <= cBlockEnd; i++ ) {
        if( isMove($i) == 1 && isTroopbar($i) == 1 ){
            return "troopbarswipe"
        }
        else if( isMove($i) == 1 ) {
            return "swipe"
        }
    }
    return "noswipe"
}


#parse Manager, manages the general parsing process
function parseManager() {
    troopbarSet = "+" #i would assume....
    while( findBlock() != "EOF" ) {
        if ( checkBlock() == "noswipe" ) {
            noswipeEdit()
        }
        else if ( checkBlock() == "troopbarswipe" ) {
            troopbarswipeEdit()
        }
    }

    #thats all i have for no, no noswipe and troopswipe support yet
}

#troopbar +- managment
function troopbarChange() {
    if( troopbarSet == "+" ) {
        troopbarSet = "-"
    }
    else {
        troopbarSet = "+"
    }
}

#edit troopbarswipe blocks, converting block not supportted yet
function troopbarswipeEdit() {
    $cBlockStart = sprintf("%s --troopbarswipe block beginning", $cBlockStart)
    troopbarChange()
    if( $cBlockEnd != "" ){
        $cBlockEnd = sprintf("%s troopbarSet = \"%s\";", $cBlockEnd, troopbarSet)
    }
    else {
        $cBlockEnd = sprintf("troopbarSet = \"%s\";", troopbarSet)
    }
}


#edit noswipe blocks (convert tDown -> tapp and comment, remove tUp, sum usleeps)
function noswipeEdit() {
    for( tmpCounter = cBlockStart; tmpCounter <= cBlockEnd; tmpCounter++ ) {
        if( $tmpCounter ~ /touchDown\(/ ) {
            tappComment = tDownAnalysis($tmpCounter)
            sub(/touchDown\([0-9]{1,2}, /, "tapp(", $tmpCounter)
            $tmpCounter = sprintf("%s%s", $tmpCounter, tappComment)
        }
        else if( $tmpCounter ~ /usleep\(/ ) {
            split($tmpCounter, tmpArray, /\(|\./)
            usleepStorage += tmpArray[2]
            $tmpCounter = ""
        }
        else if( $tmpCounter ~ /touchUp\(/ ) {
            $tmpCounter = ""
        }
    }
    if( $cBlockEnd != "" ){
        $cBlockEnd = sprintf("%s usleep(%s);", $cBlockEnd, usleepStorage)
    }
    else {
        $cBlockEnd = sprintf("usleep(%s);", usleepStorage)
    }
    #reset usleep timer storage
    usleepStorage = 0
}

#check if command is on the troopbar
function isTroopbar(command) {
    if( (orientation == "LEFT" && getXCoo(command) < toNumber(xCoo) ) || (orientation == "RIGHT" && getXCoo(command) > toNumber(xCoo) ) ) {
        return 1
    }
    else {
        return 0
    }
}

#checks if command is touchMove
function isMove(command) {
    if( command ~ /touchMove\(/ ) {
        return 1
    }
    else {
        return 0
    }
}

#converts a string-number to a number
function toNumber(stringNumber) {
    stringNumber += 0
    return stringNumber
}

BEGIN {
    filename=ARGV[1]
	if(manMeta != 1)getMeta()
	checkMeta()

    #print height, width, orientation(just test)
    print "Width: "width
    print "Height: "height
    print "Orientation: "orientation
    calcCooCs()

    RS="/(A+)A/";FS="\n"
    ORS="\n";OFS="\n";
}

{#start body
    parseManager()
    print $0 > outFile
    print $0
}##end body