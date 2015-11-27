#extracts the rotation and orientation out of script
function getMeta()
	{#function start
    print "collfrom file"
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
}#end function
	
BEGIN {
    filename=ARGV[1]
	if(manMeta != 1)getMeta()
	checkMeta()

    #print height, width, orientation(just test)
    print "Width: "width
    print "Height: "height
    print "Orientation: "orientation


    RS=""; FS="\n"
}

{#start body
}##end body