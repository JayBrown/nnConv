#!/bin/bash

# LibreOffice - LibreWriter: Convert Footnotes <> Endnotes v1.1.0 (LOconv)
# LibreWriter ➤ Convert Notes (shell script version)

LANG=en_US.UTF-8
export PATH=/usr/local/bin:$PATH
ACCOUNT=$(/usr/bin/id -un)
CURRENT_VERSION="1.10"

# check compatibility
MACOS2NO=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F. '{print $2}')
if [[ "$MACOS2NO" -le 7 ]] ; then
	echo "Error! LOconv needs at least OS X 10.8 (Mountain Lion)"
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
CACHE_DIR="${HOME}/Library/Caches/local.lcars.LOconv"
if [[ ! -e "$CACHE_DIR" ]] ; then
	mkdir -p "$CACHE_DIR"
fi

# notification function
notify () {
 	if [[ "$NOTESTATUS" == "osa" ]] ; then
		/usr/bin/osascript &>/dev/null << EOT
tell application "System Events"
	display notification "$2" with title "LOconv [" & "$ACCOUNT" & "]" subtitle "$1"
end tell
EOT
	elif [[ "$NOTESTATUS" == "tn" ]] ; then
		"$TERMNOTE_LOC/Contents/MacOS/terminal-notifier" \
			-title "LOconv [$ACCOUNT]" \
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

FILENAME=$(/usr/bin/basename "$FILE")

SUFFIX="${FILENAME##*.}"
if [[ "$SUFFIX" != "odt" ]] && [[ "$SUFFIX" != "ODT" ]] && [[ "$SUFFIX" != "fodt" ]] && [[ "$SUFFIX" != "FODT" ]]; then
	echo "Wrong format! ODT/FODT files only..."
	notify "Error! ODT/FODT files only…" "$FILENAME"
	exit # ALT: continue
fi

if [[ "$SUFFIX" == "odt" ]] || [[ "$SUFFIX" == "ODT" ]] ; then

	echo "Looking for notes in $FILENAME..."

	CONTENT=$(/usr/bin/unzip -p "$FILE" content.xml)
	if [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") == "" ]] ; then
		echo "Document doesn't contain any notes"
		notify "Error" "Document doesn't contain notes"
		exit # ALT: continue
	fi

	echo "Converting notes..."

	FILENAME="${FILENAME%.*}"
	NEW_FILENAME="$FILENAME-conv.$SUFFIX"
	TARGET_DIR=$(/usr/bin/dirname "$FILE")

	TEMP_DIR="$TARGET_DIR/temp"

	mkdir -p "$TEMP_DIR"
	cp "$FILE" "$TEMP_DIR/$NEW_FILENAME"

	INTERIM=$(echo "$CONTENT" | /usr/bin/sed 's/text:note-class="footnote"/text:note-class="interimnote"/g')
	NEW_CONTENT=$(echo "$INTERIM" | /usr/bin/sed 's/text:note-class="endnote"/text:note-class="footnote"/g' | /usr/bin/sed 's/text:note-class="interimnote"/text:note-class="endnote"/g')
	echo "$NEW_CONTENT" > "$TEMP_DIR/content.xml"

	cd "$TEMP_DIR"
	/usr/bin/zip -u "$NEW_FILENAME"

	cd /
	mv "$TEMP_DIR/$NEW_FILENAME" "$TARGET_DIR/$NEW_FILENAME"
	rm -rf "$TEMP_DIR"

elif [[ "$SUFFIX" == "fodt" ]] || [[ "$SUFFIX" == "FODT" ]] ; then

	echo "Looking for notes in $FILENAME..."

	CONTENT=$(/bin/cat "$FILE")
	if [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | /usr/bin/grep "text:note-class=\"footnote\"") == "" ]] ; then
		echo "Document doesn't contain any notes"
		notify "Error" "Document doesn't contain notes"
		exit # ALT: continue
	fi

	echo "Converting notes..."

	FILENAME="${FILENAME%.*}"
	NEW_FILENAME="$FILENAME-conv.$SUFFIX"
	TARGET_DIR=$(/usr/bin/dirname "$FILE")

	INTERIM=$(echo "$CONTENT" | /usr/bin/sed 's/text:note-class="footnote"/text:note-class="interimnote"/g')
	NEW_CONTENT=$(echo "$INTERIM" | /usr/bin/sed 's/text:note-class="endnote"/text:note-class="footnote"/g' | /usr/bin/sed 's/text:note-class="interimnote"/text:note-class="endnote"/g')
	echo "$NEW_CONTENT" > "$TARGET_DIR/$NEW_FILENAME"

fi

echo "Done: $NEW_FILENAME"
notify "Done" "$NEW_FILENAME"

done

# check for update
NEWEST_VERSION=$(/usr/bin/curl --silent https://api.github.com/repos/JayBrown/LOconv/releases/latest | /usr/bin/awk '/tag_name/ {print $2}' | xargs)
if [[ "$NEWEST_VERSION" == "" ]] ; then
	NEWEST_VERSION="0"
fi
NEWEST_VERSION=${NEWEST_VERSION//,}
if (( $(echo "$NEWEST_VERSION > $CURRENT_VERSION" | /usr/bin/bc -l) )) ; then
	notify "Update available" "LOconv v$NEWEST_VERSION"
	/usr/bin/open "https://github.com/JayBrown/LOconv/releases/latest"
fi
