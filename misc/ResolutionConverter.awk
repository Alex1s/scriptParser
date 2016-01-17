#made by Alex1s
#from scriptParser v0.7
BEGIN {
	#Variables
	outFile = ARGV[1]
	scriptStarted = 0;
	resolutionFound = 0;
	messageShown = 0;
	isCommand = 0;
	width = 0;
	height = 0;
	tmpX = 0;
	tmpY = 0;
	convertFactor = 0;

	atCommand[0] = "touchDown";
	atCommand[1] = "touchUp";
	atCommand[2] = "touchMove";
	atCommand[3] = "usleep"
	#End Variables
}

#Body
{
	#check if the script started
	if(scriptStarted == 0) {
		for(i = 0; i < 4; i++) {
			if($0 ~ atCommand[i]) {
				scriptStarted = 1;
				break;
			}
		}
	}

	if(scriptStarted == 0) {
		if(resolutionFound == 0) {
			if($0 ~ /adaptResolution/) {
				split($0, tmp, /\(|, |\)/);
				width=tmp[2];
				height=tmp[3];
				resolutionFound == 1;
			}
			else if(/^SCREEN_RESOLUTION="/) {
				split($0, tmp, /"|x/);
				width=tmp[2];
				height=tmp[3];
				resolutionFound == 1;
			}
		}
	}

	if(scriptStarted == 1) {
		if(messageShown == 0) {
				if(width == 768) {
				print("Your script is from a nonretina device and you want to convert it for a retina deive?");
				print("Type \"1\" if thats true.")
				print("Type \"2\" if thats false.")
				getline userInput < "-"
				if(userInput == 1) {
					convertFactor == 2;
				}
				if(userInput == 2) {
					print("Type 1 if you want to convert to retina, type 2 if you want to convert to non retina.")
					getline userInput < "-"
					if(userInput == 1) {convertFactor = 2} else if(userInput == 2) {convertFactor = 0.5}
				}
			}
			else if(width == 1536) {
				print("Your script is from a retina device and you want to convert it for a nonretina deive?");
				print("Type \"1\" if thats true.");
				print("Type \"2\" if thats false.");
				getline userInput < "-"
				if(userInput == 1) {
					convertFactor == 0.5;
				}
				if(userInput == 2) {
					print("Type 1 if you want to convert to retina, type 2 if you want to convert to non retina.")
					getline userInput < "-"
					if(userInput == 1) {convertFactor = 2} else if(userInput == 2) {convertFactor = 0.5}
				}
			}
			messageShown  = 1;

		}
		#check if current line is a command
		for(i = 0; i < 3; i++) {
			if($0 ~ atCommand[i]) {
				isCommand = 1;
				break;
			}
		}

		if(isCommand == 1) {
			#convert the resolution
			split($0, tmp, /, |\)/);
			if(convertFactor == 2) {
				sub(tmp[2], tmp[2] * convertFactor, $0);
				sub(tmp[3], tmp[3] * convertFactor, $0);
			}
			else if(convertFactor = 0.5) {
				sub(tmp[2], tmp[2] * convertFactor, $0);
				sub(tmp[3], tmp[3] * convertFactor, $0);
			}
		}
	}
	#print($0)
	isCommand = 0;
	print($0) > "convertedScript.lua"
}
END {
	print("ONE")
}