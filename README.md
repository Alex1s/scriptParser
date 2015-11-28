# scriptParser
parses raw AutoTouch script into scriptHelper forat with usefull comments
##How to use:
>chmod +x launcher.sh

>./launcher.sh
###parameters:
```
$1:
   - input filename
$2:
  - output filename
$3:
  - replace troop: set to "0" if you want the tapp()´s which select troops should be replaced with select(), if set to "1" tapp()´s will stay and be commented with what troop is selected by that
$4
  - replace swipe: set to "0" if any swipes in script should be untouched or set to "1" if you want to use scriptHelper for troopbar swipes
$5
  - manual metadata: enter the width, height, orientation of your device manually (via stdin or following arguemnts) by passing over "1" or let the parser get the information from the script
  !!!   Older script do not have the orientation contained, keep that in mind then running in server mode. Parser will just exit,if so.   !!!
$6
  - the width of the used device screen (first number of the two you see in the script), only needed if manual metadata input
$7
  - the height of the used device screen (second number of the two you see in the script), only needed if manual metadata input
$8
  - the orientation of the device screen when the script was recorded. ("LEFT", if home button was on the right; "RIGHT" if the home button was on the left)
$9
  - isServer: if set to "1" parser will not ask for any user inout nor output any stdout
```
So for the normal end user only the first four parameters are of importance.
