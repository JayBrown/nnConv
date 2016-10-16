#!/bin/bash

# LibreOffice Writer: Convert All Notes v1.2.0 (shell script version)
# nn-conv (compatible with: macOS, BSD, Linux, Unix etc.)

LANG=en_US.UTF-8
ACCOUNT=$(id -un)
CURRENT_VERSION="1.20"

SKIP=""

for FILE in "$@"
do

NNSTATUS=""
METHOD=""
FNSTATUS=""
ENSTATUS=""

FILENAME=$(/usr/bin/basename "$FILE")
echo "******************************************"
echo "*** Accessing file: $FILENAME"
echo "******************************************"
echo ""
SUFFIX="${FILENAME##*.}"
if [[ "$SUFFIX" != "odt" ]] && [[ "$SUFFIX" != "ODT" ]] && [[ "$SUFFIX" != "fodt" ]] && [[ "$SUFFIX" != "FODT" ]] ; then
	echo "Error! odt & fodt only"
	echo "Skipping..."
	echo ""
	if [[ "$SKIP" == "" ]] ; then
		SKIP="true"
	fi
	continue
fi

if [[ "$SUFFIX" == "odt" ]] || [[ "$SUFFIX" == "ODT" ]] ; then # convert odt

	CONTENT=$(unzip -p "$FILE" content.xml)
	# check for notes & which notes
	if [[ $(echo "$CONTENT" | grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | grep "text:note-class=\"footnote\"") == "" ]] ; then
		echo "Error: doesn't contain any notes"
		echo "Skipping..."
		echo ""
		if [[ "$SKIP" == "" ]] ; then
			SKIP="true"
		fi
		continue
	elif [[ $(echo "$CONTENT" | grep "text:note-class=\"endnote\"") != "" ]] && [[ $(echo "$CONTENT" | grep "text:note-class=\"footnote\"") == "" ]] ; then
		NNSTATUS="end"
	elif [[ $(echo "$CONTENT" | grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | grep "text:note-class=\"footnote\"") != "" ]] ; then
		NNSTATUS="foot"
	elif [[ $(echo "$CONTENT" | grep "text:note-class=\"endnote\"") != "" ]] && [[ $(echo "$CONTENT" | grep "text:note-class=\"footnote\"") != "" ]] ; then
		NNSTATUS="both"
	fi

	FILENAME="${FILENAME%.*}"
	NEW_FILENAME="$FILENAME-conv.$SUFFIX"
	TARGET_DIR=$(dirname "$FILE")

	# prompt for method
	if [[ "$NNSTATUS" == "both" ]] ; then
		echo "The document contains both footnotes and endnotes. Please choose the conversion method."
		echo "Note: a new OpenDocument text file will be created next to the original."
		echo ""
		echo "Options:"
		echo "(1) Swap Footnotes & Endnotes"
		echo "(2) Merge as Footnotes"
		echo "(3) Merge as Endnotes"
		echo ""
		echo "Please enter 1, 2, or 3"
		CHOICE_RETURN=""
		until [[ "$CHOICE_RETURN" == "true" ]]
		do
			read USER_CHOICE
			if [[ "$USER_CHOICE" == "1" ]] || [[ "$USER_CHOICE" == "2" ]] || [[ "$USER_CHOICE" == "3" ]] ; then
				CHOICE_RETURN="true"
			else
				echo "Please enter 1, 2, or 3"
			fi
		done

		if [[ "$USER_CHOICE" == "1" ]] ; then
			METHOD="swap"
		elif [[ "$USER_CHOICE" == "2" ]] ; then
			METHOD="mergefn"
		elif [[ "$USER_CHOICE" == "3" ]] ; then
			METHOD="mergeen"
		fi
		echo ""
	else
		METHOD=""
	fi

	TEMP_DIR="$TARGET_DIR/temp"
	mkdir -p "$TEMP_DIR"
	cp "$FILE" "$TEMP_DIR/$NEW_FILENAME"

	if [[ "$METHOD" == "swap" ]] ; then # exchange fn & en
		echo "Swapping footnotes <> endnotes..."
		INTERIM=$(echo "$CONTENT" | sed 's/text:note-class="footnote"/text:note-class="interimnote"/g')
		NEW_CONTENT=$(echo "$INTERIM" | sed 's/text:note-class="endnote"/text:note-class="footnote"/g' | sed 's/text:note-class="interimnote"/text:note-class="endnote"/g')
	elif [[ "$NNSTATUS" == "end" ]] || [[ "$METHOD" == "mergefn" ]] ; then # all to fn
		echo "Merging as footnotes..."
		NEW_CONTENT=$(echo "$CONTENT" | sed 's/text:note-class="endnote"/text:note-class="footnote"/g')
	elif [[ "$NNSTATUS" == "foot" ]] || [[ "$METHOD" == "mergeen" ]] ; then # all to en
		echo "Merging as endnotes..."
		NEW_CONTENT=$(echo "$CONTENT" | sed 's/text:note-class="footnote"/text:note-class="endnote"/g')
	fi

	# create new file
	echo "Creating new text file..."
	echo "$NEW_CONTENT" > "$TEMP_DIR/content.xml"

	cd "$TEMP_DIR"
	zip -u "$NEW_FILENAME"

	cd /
	mv "$TEMP_DIR/$NEW_FILENAME" "$TARGET_DIR/$NEW_FILENAME"
	rm -rf "$TEMP_DIR"

	SKIP="false"

elif [[ "$SUFFIX" == "fodt" ]] || [[ "$SUFFIX" == "FODT" ]] ; then # convert flat odt

	CONTENT=$(cat "$FILE")
	# check for notes & which notes
	if [[ $(echo "$CONTENT" | grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | grep "text:note-class=\"footnote\"") == "" ]] ; then
		echo "Error: doesn't contain any notes"
		echo "Skipping..."
		echo ""
		if [[ "$SKIP" == "" ]] ; then
			SKIP="true"
		fi
		continue
	elif [[ $(echo "$CONTENT" | grep "text:note-class=\"endnote\"") != "" ]] && [[ $(echo "$CONTENT" | grep "text:note-class=\"footnote\"") == "" ]] ; then
		NNSTATUS="end"
	elif [[ $(echo "$CONTENT" | grep "text:note-class=\"endnote\"") == "" ]] && [[ $(echo "$CONTENT" | grep "text:note-class=\"footnote\"") != "" ]] ; then
		NNSTATUS="foot"
	elif [[ $(echo "$CONTENT" | grep "text:note-class=\"endnote\"") != "" ]] && [[ $(echo "$CONTENT" | grep "text:note-class=\"footnote\"") != "" ]] ; then
		NNSTATUS="both"
	fi

	FILENAME="${FILENAME%.*}"
	NEW_FILENAME="$FILENAME-conv.$SUFFIX"
	TARGET_DIR=$(dirname "$FILE")

	# prompt for method
	if [[ "$NNSTATUS" == "both" ]] ; then
		echo "The document contains both footnotes and endnotes. Please choose the conversion method."
		echo "Note: a new OpenDocument text file will be created next to the original."
		echo ""
		echo "Options:"
		echo "(1) Swap Footnotes & Endnotes"
		echo "(2) Merge as Footnotes"
		echo "(3) Merge as Endnotes"
		echo ""
		echo "Please enter 1, 2, or 3"
		CHOICE_RETURN=""
		until [[ "$CHOICE_RETURN" == "true" ]]
		do
			read USER_CHOICE
			if [[ "$USER_CHOICE" == "1" ]] || [[ "$USER_CHOICE" == "2" ]] || [[ "$USER_CHOICE" == "3" ]] ; then
				CHOICE_RETURN="true"
			else
				echo "Please enter 1, 2, or 3"
			fi
		done

		if [[ "$USER_CHOICE" == "1" ]] ; then
			METHOD="swap"
		elif [[ "$USER_CHOICE" == "2" ]] ; then
			METHOD="mergefn"
		elif [[ "$USER_CHOICE" == "3" ]] ; then
			METHOD="mergeen"
		fi
		echo ""
	else
		METHOD=""
	fi

	if [[ "$METHOD" == "swap" ]] ; then # exchange fn & en
		echo "Swapping footnotes <> endnotes..."
		INTERIM=$(echo "$CONTENT" | sed 's/text:note-class="footnote"/text:note-class="interimnote"/g')
		NEW_CONTENT=$(echo "$INTERIM" | sed 's/text:note-class="endnote"/text:note-class="footnote"/g' | sed 's/text:note-class="interimnote"/text:note-class="endnote"/g')
	elif [[ "$NNSTATUS" == "end" ]] || [[ "$METHOD" == "mergefn" ]] ; then # all to fn
		NEW_CONTENT=$(echo "$CONTENT" | sed 's/text:note-class="endnote"/text:note-class="footnote"/g')
		echo "Merging as footnotes..."
	elif [[ "$NNSTATUS" == "foot" ]] || [[ "$METHOD" == "mergeen" ]] ; then # all to en
		echo "Merging as endnotes..."
		NEW_CONTENT=$(echo "$CONTENT" | sed 's/text:note-class="footnote"/text:note-class="endnote"/g')
	fi

	# create new file
	echo "Creating new text file..."
	echo "$NEW_CONTENT" > "$TARGET_DIR/$NEW_FILENAME"

	SKIP="false"

fi

if [[ "$SKIP" == "false" ]] ; then
	echo "Conversion finished"
	echo ""
fi

done

if [[ "$SKIP" == "true" ]] ; then
	echo "*** Exiting... ***"
	exit
fi

echo "*** Done ***"

# check for update
echo "Checking for update..."
NEWEST_VERSION=$(curl --silent https://api.github.com/repos/JayBrown/nnConv/releases/latest | awk '/tag_name/ {print $2}' | xargs)
if [[ "$NEWEST_VERSION" == "" ]] ; then
	NEWEST_VERSION="0"
fi
NEWEST_VERSION=${NEWEST_VERSION//,}
if (( $(echo "$NEWEST_VERSION > $CURRENT_VERSION" | bc -l) )) ; then
	echo "Update available: nnConv v$NEWEST_VERSION"
	open "https://github.com/JayBrown/nnConv/releases/latest"
else
	echo "nnConv is up to date"
fi
