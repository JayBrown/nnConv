![LOconv-platform-macos](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![LOconv-code-shell](https://img.shields.io/badge/code-shell-yellow.svg)
[![LOconv-depend-tnote](https://img.shields.io/badge/dependency-terminal--notifier%201.7.1-green.svg)](https://github.com/alloy/terminal-notifier)
[![LOconv-license](http://img.shields.io/badge/license-MIT+-blue.svg)](https://github.com/JayBrown/LOconv/blob/master/license.md)

# LibreOffice – LibreWriter: Convert Footnotes <> Endnotes <img src="https://github.com/JayBrown/LOconv/blob/master/img/jb-img.png" height="20px"/>
**macOS workflow and shell script to convert footnotes to endnotes and vice versa in OpenDocument Text files (odt)**

In **Microsoft Word** it's easy to convert footnotes to endnotes or vice versa, a functionality important to many scientific authors. Even though users have requested this feature to be implemented in **LibreWriter** (part of [**LibreOffice**](http://www.libreoffice.org)) for many years, the developers haven't done so yet.

So if you are a LibreOffice user, you need to do it manually, either within the document, or by changing the odt file's `content.xml`. The latter is automated by this script.

Before running the script on an OpenDocument Text file, you should save the file, if you're currently working on it in LibreWriter. If your text file contains foot- and endnotes, they will all be converted, footnotes to endnotes, and endnotes to footnotes.

**Note:** If you just want LibreWriter to *display* your footnotes at the end of your document without converting, you can do so by selecting the position "End of document" in the menu **Tools** > **Footnotes and Endnotes…**.

## Installation
* [Download the latest DMG](https://github.com/JayBrown/LOconv/releases) and open

### Workflow
* Double-click on the workflow file to install
* If you encounter problems, open it with Automator and save/install from there
* Standard Finder integration in the Services menu

### terminal-notifier [optional, recommended]
More information: [terminal-notifier](https://github.com/alloy/terminal-notifier)

You need to have Spotlight enabled for `mdfind` to locate the terminal-notifier.app on your volume; if you don't install terminal-notifier, or if you have deactivated Spotlight, LOconv will call notifications via AppleScript instead

#### Installation method #1
Install using [Homebrew](http://brew.sh) with `brew install terminal-notifier` (or with a similar manager)

#### Installation method #2
* move the terminal-notifier zip archive from the DiMaGo disk image to a folder on your main volume
* unzip the application and move it to a suitable location, e.g. to `/Applications`, `/Applications/Utilities`, or `$HOME/Applications`

### Shell script [optional]
Only necessary if for some reason you want to run this from the shell or another shell script. For normal use the workflow will be sufficient.

* Move the script `LOconv.sh` into `/usr/local/bin`
* In your shell enter `chmod +x /usr/local/bin/LOconv.sh`
* Run the script with `LOconv.sh /path/to/target`

## Uninstall
Remove the following files or folders:

```
$HOME/Library/Caches/local.lcars.LOconv
$HOME/Library/Services/LibreWriter\ ➤\ Convert Notes.workflow
/usr/local/bin/LOconv.sh
```
