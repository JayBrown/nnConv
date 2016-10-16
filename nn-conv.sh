#!/bin/bash

# LibreOffice Writer: Convert All Notes v1.2.0 (shell script version)

LANG=en_US.UTF-8
export PATH=/usr/local/bin:$PATH
ACCOUNT=$(/usr/bin/id -un)
CURRENT_VERSION="1.20"

# check compatibility
MACOS2NO=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F. '{print $2}')
if [[ "$MACOS2NO" -le 7 ]] ; then
	echo "Error! nnConv needs at least OS X 10.8 (Mountain Lion)"
	echo "Exiting..."
	INFO=$(/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set userChoice to button returned of (display alert "Error! Minimum OS requirement:" & return & "OS X 10.8 (Mountain Lion)" ¬
		as critical ¬
		buttons {"Quit"} ¬
		default button 1 ¬
		giving up after 60)
end tell
EOT)
	exit
fi

# cache directory
CACHE_DIR="${HOME}/Library/Caches/local.lcars.nnConv"
if [[ ! -e "$CACHE_DIR" ]] ; then
	mkdir -p "$CACHE_DIR"
fi

# notification function
notify () {
 	if [[ "$NOTESTATUS" == "osa" ]] ; then
		/usr/bin/osascript &>/dev/null << EOT
tell application "System Events"
	display notification "$2" with title "nnConv [" & "$ACCOUNT" & "]" subtitle "$1"
end tell
EOT
	elif [[ "$NOTESTATUS" == "tn" ]] ; then
		"$TERMNOTE_LOC/Contents/MacOS/terminal-notifier" \
			-title "nnConv [$ACCOUNT]" \
			-subtitle "$1" \
			-message "$2" \
			-appIcon "$ICON_LOC" \
			>/dev/null
	fi
}

# detect/create icon for terminal-notifier and osascript windows
ICON_LOC="$CACHE_DIR/lcars.png"
if [[ ! -f "$ICON_LOC" ]] ; then
	ICON64="iVBORw0KGgoAAAANSUhEUgAAAIwAAACMEAYAAAD+UJ19AAACYElEQVR4nOzUsW1T
URxH4fcQSyBGSPWQrDRZIGUq2IAmJWyRMgWRWCCuDAWrGDwAkjsk3F/MBm6OYlnf
19zqSj/9i/N6jKenaRpjunhXV/f30zTPNzePj/N86q9fHx4evi9j/P202/3+WO47
D2++3N4uyzS9/Xp3d319+p3W6+fncfTnqNx3Lpbl3bf/72q1+jHPp99pu91sfr4f
43DY7w+fu33n4tVLDwAul8AAGYEBMgIDZAQGyAgMkBEYICMwQEZggIzAABmBATIC
A2QEBsgIDJARGCAjMEBGYICMwAAZgQEyAgNkBAbICAyQERggIzBARmCAjMAAGYEB
MgIDZAQGyAgMkBEYICMwQEZggIzAABmBATICA2QEBsgIDJARGCAjMEBGYICMwAAZ
gQEyAgNkBAbICAyQERggIzBARmCAjMAAGYEBMgIDZAQGyAgMkBEYICMwQEZggIzA
ABmBATICA2QEBsgIDJARGCAjMEBGYICMwAAZgQEyAgNkBAbICAyQERggIzBARmCA
jMAAGYEBMgIDZAQGyAgMkBEYICMwQEZggIzAABmBATICA2QEBsgIDJARGCAjMEBG
YICMwAAZgQEyAgNkBAbICAyQERggIzBARmCAjMAAGYEBMgIDZAQGyAgMkBEYICMw
QEZggIzAABmBATICA2QEBsgIDJARGCAjMEBGYICMwAAZgQEyAgNkBAbICAyQERgg
IzBARmCAjMAAGYEBMgIDZAQGyAgMkBEYICMwQEZggIzAABmBATICA2QEBsgIDJAR
GCAjMEBGYICMwAAZgQEy/wIAAP//nmUueblZmDIAAAAASUVORK5CYII="
	echo "$ICON64" > "$CACHE_DIR/lcars.base64"
	/usr/bin/base64 -D -i "$CACHE_DIR/lcars.base64" -o "$ICON_LOC" && rm -rf "$CACHE_DIR/lcars.base64"
fi
if [[ -f "$CACHE_DIR/lcars.base64" ]] ; then
	rm -rf "$CACHE_DIR/lcars.base64"
fi

# look for terminal-notifier
TERMNOTE_LOC=$(/usr/bin/mdfind "kMDItemCFBundleIdentifier == 'nl.superalloy.oss.terminal-notifier'" 2>/dev/null | /usr/bin/awk 'NR==1')
if [[ "$TERMNOTE_LOC" == "" ]] ; then
	NOTESTATUS="osa"
else
	NOTESTATUS="tn"
fi

for FILE in "$1" # ALT: "$@"
do

NNSTATUS=""
METHOD=""

FILENAME=$(/usr/bin/basename "$FILE")
SUFFIX="${FILENAME##*.}"
if [[ "$SUFFIX" != "odt" ]] && [[ "$SUFFIX" != "ODT" ]] && [[ "$SUFFIX" != "fodt" ]] && [[ "$SUFFIX" != "FODT" ]]; then
	notify "Error! ODT/FODT files only…" "$FILENAME"
	exit # ALT: continue
fi

if [[ "$SUFFIX" == "odt" ]] || [[ "$SUFFIX" == "ODT" ]] ; then # convert odt

	CONTENT=$(/usr/bin/unzip -p "$FILE" content.xml)
	# check for notes & which notes
	if [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") == "" ]] ; then
		notify "Error: no notes" "$FILENAME"
		exit # ALT: continue
	elif [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") != "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") == "" ]] ; then
		NNSTATUS="end"
	elif [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") != "" ]] ; then
		NNSTATUS="foot"
	elif [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") != "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") != "" ]] ; then
		NNSTATUS="both"
	fi

	FILENAME="${FILENAME%.*}"
	NEW_FILENAME="$FILENAME-conv.$SUFFIX"
	TARGET_DIR=$(/usr/bin/dirname "$FILE")

	# prompt for method
	if [[ "$NNSTATUS" == "both" ]] ; then
		METHOD=$(/usr/bin/osascript 2>/dev/null << EOT
tell application "System Events"
	activate
	set theLogoPath to ((path to library folder from user domain) as text) & "Caches:local.lcars.nnConv:lcars.png"
	set theMethod to button returned of (display dialog "The document contains both footnotes and endnotes. Please choose the conversion method. A new OpenDocument text file will be created next to the original." ¬
		buttons {"Merge as Footnotes", "Merge as Endnotes", "Swap Footnotes & Endnotes"} ¬
		default button 3 ¬
		with title "Convert ODT notes: " & "$FILENAME" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
theMethod
EOT)
	else
		METHOD=""
	fi

	TEMP_DIR="$TARGET_DIR/temp"
	mkdir -p "$TEMP_DIR"
	cp "$FILE" "$TEMP_DIR/$NEW_FILENAME"

	if [[ "$METHOD" == "Swap Footnotes & Endnotes" ]] ; then # exchange fn & en
		INTERIM=$(echo "$CONTENT" | /usr/bin/sed 's/text:note-class="footnote"/text:note-class="interimnote"/g')
		NEW_CONTENT=$(echo "$INTERIM" | /usr/bin/sed 's/text:note-class="endnote"/text:note-class="footnote"/g' | /usr/bin/sed 's/text:note-class="interimnote"/text:note-class="endnote"/g')
	elif [[ "$NNSTATUS" == "end" ]] || [[ "$METHOD" == "Merge as Footnotes" ]] ; then # all to fn
		NEW_CONTENT=$(echo "$CONTENT" | /usr/bin/sed 's/text:note-class="endnote"/text:note-class="footnote"/g')
	elif [[ "$NNSTATUS" == "foot" ]] || [[ "$METHOD" == "Merge as Endnotes" ]] ; then # all to en
		NEW_CONTENT=$(echo "$CONTENT" | /usr/bin/sed 's/text:note-class="footnote"/text:note-class="endnote"/g')
	fi

	# create new file
	echo "$NEW_CONTENT" > "$TEMP_DIR/content.xml"

	cd "$TEMP_DIR"
	/usr/bin/zip -u "$NEW_FILENAME"

	cd /
	mv "$TEMP_DIR/$NEW_FILENAME" "$TARGET_DIR/$NEW_FILENAME"
	rm -rf "$TEMP_DIR"

elif [[ "$SUFFIX" == "fodt" ]] || [[ "$SUFFIX" == "FODT" ]] ; then # convert flat odt

	CONTENT=$(/bin/cat "$FILE")
	# check for notes & which notes
	if [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") == "" ]] ; then
		notify "Error: no notes" "$FILENAME"
		exit # ALT: continue
	elif [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") != "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") == "" ]] ; then
		NNSTATUS="end"
	elif [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") != "" ]] ; then
		NNSTATUS="foot"
	elif [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") != "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") != "" ]] ; then
		NNSTATUS="both"
	fi

	FILENAME="${FILENAME%.*}"
	NEW_FILENAME="$FILENAME-conv.$SUFFIX"
	TARGET_DIR=$(/usr/bin/dirname "$FILE")

	# prompt for method
	if [[ "$NNSTATUS" == "both" ]] ; then
		METHOD=$(/usr/bin/osascript 2>/dev/null << EOT
tell application "System Events"
	activate
	set theLogoPath to ((path to library folder from user domain) as text) & "Caches:local.lcars.nnConv:lcars.png"
	set theMethod to button returned of (display dialog "The document contains both footnotes and endnotes. Please choose the conversion method. A new OpenDocument text file will be created next to the original." ¬
		buttons {"Merge as Footnotes", "Merge as Endnotes", "Swap Footnotes & Endnotes"} ¬
		default button 3 ¬
		with title "Convert FODT notes: " & "$FILENAME" ¬
		with icon file theLogoPath ¬
		giving up after 180)
end tell
theMethod
EOT)
	else
		METHOD=""
	fi

	if [[ "$METHOD" == "Swap Footnotes & Endnotes" ]] ; then # exchange fn & en
		INTERIM=$(echo "$CONTENT" | /usr/bin/sed 's/text:note-class="footnote"/text:note-class="interimnote"/g')
		NEW_CONTENT=$(echo "$INTERIM" | /usr/bin/sed 's/text:note-class="endnote"/text:note-class="footnote"/g' | /usr/bin/sed 's/text:note-class="interimnote"/text:note-class="endnote"/g')
	elif [[ "$NNSTATUS" == "end" ]] || [[ "$METHOD" == "Merge as Footnotes" ]] ; then # all to fn
		NEW_CONTENT=$(echo "$CONTENT" | /usr/bin/sed 's/text:note-class="endnote"/text:note-class="footnote"/g')
	elif [[ "$NNSTATUS" == "foot" ]] || [[ "$METHOD" == "Merge as Endnotes" ]] ; then # all to en
		NEW_CONTENT=$(echo "$CONTENT" | /usr/bin/sed 's/text:note-class="footnote"/text:note-class="endnote"/g')
	fi

	# create new file
	echo "$NEW_CONTENT" > "$TARGET_DIR/$NEW_FILENAME"

fi

notify "Conversion finished" "$NEW_FILENAME"

done

# check for update
NEWEST_VERSION=$(/usr/bin/curl --silent https://api.github.com/repos/JayBrown/nnConv/releases/latest | /usr/bin/awk '/tag_name/ {print $2}' | xargs)
if [[ "$NEWEST_VERSION" == "" ]] ; then
	NEWEST_VERSION="0"
fi
NEWEST_VERSION=${NEWEST_VERSION//,}
if (( $(echo "$NEWEST_VERSION > $CURRENT_VERSION" | /usr/bin/bc -l) )) ; then
	notify "Update available" "nnConv v$NEWEST_VERSION"
	/usr/bin/open "https://github.com/JayBrown/nnConv/releases/latest"
fi
