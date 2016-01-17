#made by Alex1s :)
#version 0.7



##########
#data collecting functions
##########

#extracts the rotation and orientation out of the script
function getData(){
	while ( (getline extLine < filename) > 0) {
		#try to get the resolution from "adaptResolution()"
		if( match(extLine, /^adaptResolution\(/) != 0 && resFound != 1) {
			split(extLine, metaTMP, /\(|, |\)/)
			width=metaTMP[2]
			height=metaTMP[3]
			if ( checkResolution(width, height) == 1 ) {
				resFound=1
			}
        }
		#try to get the resolution from "#SCREEN_RESOLUTION="
		else if( match(extLine, /^SCREEN_RESOLUTION="/) != 0 && resFound != 1) {
			split(extLine, metaTMP, /"|x/)
			width=metaTMP[2]
			height=metaTMP[3]
			if ( checkResolution(width, height) == 1 ) {
				resFound=1
			}
		}
		#try to get the orientation from "adpatOrientation()"
		else if( match(extLine, /^adaptOrientation\(/) != 0 && oriFound != 1) {
            split(extLine, metaTMP, /_|\)/)
            orientation=metaTMP[3]
            if( checkOrientation(orientation) ) {
                oriFound=1
            }
		}
	}
	#close the input file again
	close(filename)
}

function checkSettings(){
    if(isServer != 1){
        # ask for troop replacement
        print "Do you want tapp´s that select a troop to be replaced with sellect´s?"
        print "For \"yes\" type \"1\""
        print "for \"no\" type \"2\""
        print "Recommended: \"1\""

        getline userInput < "-"
        if( userInput == 1 ){
            replaceTroop = 1
        }
        else if( userInput == 2 ) {
            replaceTroop = 0
        }
        else {
            exitSadly()
        }

        #ask for troopbarswipe replacement
        print "Do you want to replace troopbar swipes with scriptHelper´s troopbar swipes?"
        print "For \"yes\" type \"1\""
        print "for \"no\" type \"2\""
        print "Recommended: \"1\""

        getline userInput < "-"
        if( userInput == 1 ){
            replaceTroopSwipe = 1
        }
        else if( userInput == 2 ) {
            replaceTroopSwipe = 0
        }
        else {
            exitSadly()
        }
    }
}

#check if the resolution is correct (return 1) or incorrect (return 0)
function checkResolution(width, height) {
    #check if it is a non-retina or if it is a retina resolution
    if( (width == 768 && height == 1024) || (width == 1536 && height == 2048) ) {
        return 1
    }
    else {
        return 0
    }
}

#check if the orientation is correct (return 1) or incorrect (return 0)
function checkOrientation(orientation) {
    if( orientation == "RIGHT" || orientation == "LEFT" ) {
        return 1
    }
    else {
        return 0
    }
}

#if something went wrong, take the resolution information from the user
function resolutionError() {
    print "ERROR! The resolution seems to be incorrect.\nPlease select one of the following..."
    print "retina resolution (1536x2048): \"1\""
    print "no retina resolution (768x1024): \"2\""
    print "Type \"exit\" to exit."
    getline userInput < "-"

    if( userInput == 1 ){
        width = 1536; height = 2048;
    }
    else if( userInput == 2 ) {
        width = 768; height = 1024;
    }
    else {
        exitSadly()
    }
}

#if something went wrong, take the orientation information from the user
function orientationError() {
    print "ERROR! The orientation seems to be incorrect.\nPlease select one of the following..."
    print "orientation is LEFT (home button on the right): \"1\""
    print "orientation is RIGHT (home button on the left): \"2\""
    print "Type \"exit\" to exit."
    getline userInput < "-"

    if( userInput == 1 ){
        orientation = "LEFT"
    }
    else if( userInput == 2 ) {
        orientation = "RIGHT"
    }
    else {
        exitSadly()
    }
}

function troopCountError(){
    if(totalSlots < 12) {
        print "ERROR! You entered "totalSlots" Slots.\n you need to enter at least 12 in \"slotNames.txt\"."
    }
    if(totalSlots > 24) {
        print "ERROR! You entered "totalSlots" Slots.\n you need to enter 24 or less Slots in \"slotNames.txt\"."
    }
}

#sadly exit this script
function exitSadly() {
    print "Something went wrong. :(\nExiting..."
    exit 1
}


#checks if the data is correct
function checkData() {
    if( checkResolution(width, height) == 0 ) {
		if( isServer == 1 ) {
			exit 1
		}
		else {
        	resolutionError()		
		}

    }
    if ( checkOrientation(orientation) == 0 ) {
		if( isServer == 1 ) {
			exit 1
		}
		else {
        	orientationError()
		}
    }
}


##########
#get functions
##########

#get ID from a command
function getCommandID(command) {
    split(command, tmpArray, "[\(,]")
    return tmpArray[2]+0
}

#get xCoo from a Command
function getXCoo(command) {
    split(command, tmpArray, / |,|\)/)
    return tmpArray[3]+0
}

#get yCoo from a command
function getYCoo(aTCommand) {
    split(aTCommand, tmpArray, / |,|\)/)
    return tmpArray[5]+0
}

#get time from a usleep command
function getTime(command) {
    split(command, tmpArray, /\(|\./)
    return tmpArray[2]+0
}

#get the total amount if time "slept" in the current block
function getBlockTime(     usleepStorage, i) {
    for(i=cBlockStart; i <= cBlockEnd; i++) {
        if( $i ~ /usleep\(/ ) {
            usleepStorage += getTime($i) 
        }
    }
    return usleepStorage
}

#get slot names from slots.txt
function getSlotNames(     i) {
	for(i=1; i <= 24; i++) {
        getline extLine < "slotNames.txt"

        split(extLine, tmpArray, /=/)
        if(tmpArray[2] != "") {
            tmpSlotName = tmpArray[2]
            totalSlots += 1
        }
        else {
            tmpSlotName = "Slot"i
        }
        slotName[i] = tmpSlotName
    }
    close("slotNames.txt")
    noAccesSlots = totalSlots-12
    #debug
    #for(i=1; i <= 24; i++) {
    #    print slotName[i]
    #}
}


##########
#check functions
##########

#check if current line selects king or queen, sets "queenSelected" and "kingSelected"
#returns 1 if hero was already selected and tapp comment selcts him again (hero ability)
function wasHeroSelected(hero, tappComment){
    if(hero == "queen"){
        #check if queen is in tapp comment
        if(tappComment ~ /queen/){
            if(queenSelected == 1){
                return 1
            }
            else{
                queenSelected = 1
                return 0
            } 
        }
    }


    if(hero == "king"){
        #check if king is in tapp comment
        if(tappComment ~ /king/){
            if(kingSelected == 1){
                return 1
            }
            else{
                kingSelected = 1
                return 0
            } 
        }
    }

    if(hero == "warden"){
        #check if king is in tapp comment
        if(tappComment ~ /warden/){
            if(wardenSelected == 1){
                return 1
            }
            else{
                wardenSelected = 1
                return 0
            } 
        }
    }
}

#check if command is on the troopbar
function isTroopbar(command) {
    if( getXCoo(command) > FiBSlot["x"] && getXCoo(command) < FiESlot["x"] ) {
        return 1
    }
    else {
        return 0
    }

}

#checks if command is a touchMove()
function isMove(command) {
    if( command ~ /touchMove\(/ ) {
        return 1
    }
    else {
        return 0
    }
}


##########
#misc functions
##########

function printFinal(     i) {
    for(i=1; i <= NF; i++){
        #&& $i+1 ~ /tapp\(/ || $i+1 ~ /touchDown\(/
        if($i !~ /^[[:space:]]*$/) {
            print $i >> outFile
        }
        else if($(i+1) ~ /select\(/ || $(i+1) ~ /touchDown\(/) {
            print "" >> outFile
        }
    }
}

#converts a string-number to a number
function toNumber(stringNumber) {
    stringNumber += 0
    return stringNumber
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

#clears the current block
function clearBlock(     i) {
    for(i=cBlockStart; i <= cBlockEnd; i++) {
        $i = ""
    }
}

#replaces x and y coordinates with "recalc(x)" and "recalc(y)" in the current Block
function cooReplace(command,     x, y, i){
    x = getXCoo(command)
    y = getYCoo(command)

    #replace x coo
    sub(x, "recalcX("x")", command)
    #replace y coo
    sub(y, "recalcY("y")", command)

    return command
}


#calculate coordinates
function calcCooCs(     i) {
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
	LeBSlot["x"] = sprintf("%.0f", width*0.00000)

    #LeEnd of slots
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
	LeESlot["x"] = sprintf("%.0f", width*0.13021)

    #redefine coordinates if the rotation is RIGHT
    if( orientation == "RIGHT" ) {
        tmpCounter = 13
        for(n = 1; n <= 12; n++) {
            tmpCounter--
            #tmp save of Coos
            RiBSlot[n] = LeBSlot[tmpCounter]
            RiESlot[n] = LeESlot[tmpCounter]
        }
		#swap to make it between-compareable
		RiBSlot["x"] = width-LeESlot["x"]
		RiESlot["x"] = width-LeBSlot["x"]
		
        #put converted data in Fi (Final) Arrays
        for(n = 1; n <= 12; n++) {
            FiBSlot[n] = RiBSlot[n]
            FiESlot[n] = RiESlot[n]
        }
		FiBSlot["x"] = RiBSlot["x"]
		FiESlot["x"] = RiESlot["x"]
    }
    else {
        for(n = 1; n <= 12; n++) {
            FiBSlot[n] = LeBSlot[n]
            FiESlot[n] = LeESlot[n]
        }
		FiBSlot["x"] = LeBSlot["x"]
		FiESlot["x"] = LeESlot["x"]
    }
	#convert to number
	for( i=1; i <= 12; i++ ) {
		FiBSlot[i] += 0
		FiESlot[i] += 0
	}
	FiBSlot["x"] += 0
	FiESlot["x"] += 0
}


##########
#parse functions
##########

#find the beginning and end of the next or first block
function findBlock(     i) {
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
            cBlockID = getCommandID($cBlockStart)
            tmpRegex = sprintf("touchUp\\\((%s)", cBlockID)
        }
        tmpCounter = tmpCounter+1
    }


    #find end of block
    while ( tmpCounter <= NF && cBlockEndFound != 1 ) {
        #if touchUp is found and nestTDownCounter == 0, finsihed
        if( $tmpCounter ~ tmpRegex && nestTDownCounter == 0 ){
            cBlockEnd = tmpCounter
            cBlockEndFound = 1
        }
        #if a new tDown is found, add id to tmpRegex
        else if( $tmpCounter ~ /touchDown\(/ ) {
            #get ID from TDown found
            cBlockID = getCommandID($tmpCounter)
            sub(/\(\(/, "&"cBlockID"|", tmpRegex)
            nestTDownCounter = nestTDownCounter+1
        }
        #if touchUp is found but nested > 0, reduce regex by that id
        else if( $tmpCounter ~ tmpRegex && nestTDownCounter > 0 ) {
            cBlockIDRemove = getCommandID( $tmpCounter )
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
        if( $tmpCounter ~ /touchDown\(/ ) {
            cBlockEnd = tmpCounter-1
            cBlockEndFound = 1
        }
        tmpCounter = tmpCounter+1
    }

    #if not found its probably the last line or end of file
    if(cBlockEndFound != 1 || cBlockStartFound != 1) {
        if(cBlockStartFound == 1){
            cBlockEnd = NF
            #print cBlockEnd
        }
        else {
            return "EOF"
        }
    }
    #cBlockEndFound = 0


    #if( cBlockStartFound == 0 ) {
    #    return "EOF"
    #}

    #debugg printn
	#print "FOUND BEGINNING: " cBlockStart
	#print "FOUND END at: "cBlockEnd

    cBlockStartFound = 0
    cBlockEndFound = 0
}



#tDown Analysis, returns a comment string
function tDownAnalysis(tDownLine,     i) {
    #get Y and X coo
    tDAnalysisX = getXCoo(tDownLine)
    tDAnalysisY = getYCoo(tDownLine)

    tDAnalysisX += 0
    #check if a troop select
    if( isTroopbar(tDownLine) == 1 ) {
        #check what slot
        for( n = 1; n <= 12; n++ ) {
            #print "checking if Y="tDAnalysisY"is in slot "n" which is between "FiBSlot[n]"and "FiBSlot[n]

            #conv to ints -.-
            tDAnalysisY += 0
            FiBSlot[n] += 0
            FiESlot[n] += 0
            if( tDAnalysisY >= FiBSlot[n] && tDAnalysisY <= FiESlot[n] ) {
                #if troopbar was negative add notVisible to it
                if(troopbarSet == "-") {
                    newSlotNum = n+noAccesSlots
                }
                else {
                    newSlotNum = n
                }

                if( replaceTroop == 1 ) {
                    returnValue = sprintf ("select(\""slotName[newSlotNum]"\");")
                }
                else {
                    returnValue = sprintf ("--select(\""slotName[newSlotNum]"\");")

                }
                return returnValue
            }
        }
    }
    return ""
}

#parse Manager, manages the general parsing process
function parseManager(     i) {
    troopbarSet = "+" #i would assume....
    while( findBlock() != "EOF" ) {
        #print "no loop"
        if( checkBlock() == "noswipe" ) {
            noswipeEdit()
        }
        else if( checkBlock() == "troopbarswipe" ) {
            troopbarswipeEdit()
        }
        else if(checkBlock() == "swipe"){
            swipeEdit()
        }
    }
}

#checks the type of the current block
#@return: "noswipe" or "troopswipe" or "swipe"
function checkBlock(     i) {
    tmpCounter = cBlockStart
    for( i = cBlockStart; i <= cBlockEnd; i++ ) {
        if( isMove($i) == 1 && isTroopbar($i) == 1 ){
            return "troopbarswipe"
        }
        else if( isMove($i) == 1 && isTroopbar != 1) {
            return "swipe"
        }
    }
    return "noswipe"
}

#edit swipe blocks
function swipeEdit(     i){
    for(i=1; i <= cBlockEnd; i++){
        if($i ~ /touchDown\(/ || $i ~ /touchUp\(/ || $i ~ /touchMove\(/) {
            $i = cooReplace($i)
        }
    }
}

#edit troopbarswipe blocks
function troopbarswipeEdit(     comment, blockTime, i) {
    troopbarChange()
    blockTime = getBlockTime()

    #error if block time is too short
    if(blockTime-1000000 < 0) {
        if(isServer == 1) {
            exit 1
        }
        else {
            print "The troopbar-swipe in the block starting at line "cBlockStart" was too fast. Please adjust the timing manually."
            blockTime = 0
            comment = "--need to remove "blockTime-1000000" of usleep time"
        }
    }
    else {
        #substract the time it takes for scriptHelper to swipe
        blockTime -= 1000000 
    }

    #actual action
    #print replaceTroopSwipe
    if(replaceTroopSwipe == 1) {
        if(replaceTroop == 1) {
            clearBlock()
            $cBlockStart = "usleep("blockTime");"comment
        }
        else {
            clearBlock()
            $cBlockStart = "usleep("blockTime");"comment
            $(cBlockStart+1) = "setTroopbar(\""troopbarSet"\");"
        }
    }
    else {
        cooRecalc()
        $cBlockStart = sprintf("%s --troopbarswipe block beginning", $cBlockStart)
        troopbarChange()
        if( $cBlockEnd != "" ){
            $cBlockEnd = sprintf("%s troopbarSet = \"%s\";", $cBlockEnd, troopbarSet)
        }
        else {
            $cBlockEnd = sprintf("troopbarSet = \"%s\";", troopbarSet)
        }
    }
}

#edit noswipe blocks (convert tDown -> tapp and comment, remove tUp, sum usleeps)
function noswipeEdit(     i) {
    for( tmpCounter = cBlockStart; tmpCounter <= cBlockEnd; tmpCounter++ ) {
        #if it is a touchDown
        if( $tmpCounter ~ /touchDown\(/ ) {
            tappComment = tDownAnalysis($tmpCounter)
            sub(/touchDown\([0-9]{1,2}, /, "tapp(", $tmpCounter)
            if(replaceTroop == 1 && tappComment != "") {
                $tmpCounter = ""
            }
            $tmpCounter = sprintf("%s%s", $tmpCounter, tappComment)

            #search for usleeps and sum them in usleepStorage
            sleepSearchCount = tmpCounter+1
            #this loop collect usleep timings until next touchDown
            while(sleepSearchCount <= cBlockEnd && match($sleepSearchCount, /touchDown\(/) < 1) {
                if($sleepSearchCount ~ /usleep\(/ ) {
                    usleepStorage += getTime($sleepSearchCount)
                    $sleepSearchCount = ""
                    emptyLine = sleepSearchCount
                }
                sleepSearchCount += 1
            }
            if(usleepStorage != 0 && (tappComment == "" || wasHeroSelected("queen", tappComment) == 1 || wasHeroSelected("king", tappComment) == 1 || wasHeroSelected("warden", tappComment) == 1) ) {
                $emptyLine = sprintf("usleep(%s);",  usleepStorage)
            }
           else if(usleepStorage != 0 && (queenSelected == 1 || kingSelected == 1 || wardenSelected == 1)) {
                #its a slect put the usleep before the tapp
                sleepSearchCount = cBlockEnd-1 
                while( prevSleepFound != 1 && sleepSearchCount > 0 ) {
                    if( $sleepSearchCount ~ /usleep\(/ ) {
                        usleepStorage += getTime($sleepSearchCount)
                        $sleepSearchCount = sprintf("usleep(%s);",  usleepStorage)
                        prevSleepFound = 1
                    }
                    sleepSearchCount--
                }
            }
            #reset usleep timer storage
            usleepStorage = 0
        }


        #if it is a touchUp
        else if( $tmpCounter ~ /touchUp\(/ ) {
            $tmpCounter = ""
        }
    }

    #reset is a troop select
    isTroopSelect = 0
    #reset prev usleep found
    prevSleepFound = 0
}


BEGIN {
    filename=ARGV[1]
    if( manData != 1 ) {
        getData()
    }
	checkData()
	calcCooCs()
    getSlotNames()
    checkSettings()
    troopCountError()

    #print height, width, orientation(for debug)
    #print "Width: "width
    #print "Height: "height
    #print "Orientation: "orientation

    RS="/(A+)A/";FS="\n"
    ORS="\n";OFS="\n";
}

#body 
{
	parseManager()
	printFinal()
}