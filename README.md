![nnConv-platform-macos](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![nnConv-code-shell](https://img.shields.io/badge/code-shell-yellow.svg)
[![nnConv-depend-tnote](https://img.shields.io/badge/dependency-terminal--notifier%201.7.1-green.svg)](https://github.com/alloy/terminal-notifier)
[![nnConv-license](http://img.shields.io/badge/license-MIT+-blue.svg)](https://github.com/JayBrown/nnConv/blob/master/license.md)

# LibreOffice Writer: Convert All Notes <img src="https://github.com/JayBrown/nnConv/blob/master/img/jb-img.png" height="20px"/>
**macOS workflow and shell script for one-shot conversion of all footnotes or endnotes in OpenDocument text files (odt/fodt) for use e.g. in LibreOffice Writer**

![nnConv-screengrab](https://github.com/JayBrown/nnConv/blob/master/img/nnConv-screengrab.png)

In **Microsoft Word** it's easy to convert all footnotes to endnotes (or vice versa) in one shot, a functionality important to many scientific authors. Even though users have requested this feature to be implemented in [**LibreOffice Writer**](http://www.libreoffice.org) (for many years apparently), the developers haven't done so yet. So if you are a user of LibreOffice Writer, you need to do it manually: the only official option is to do it one note at a time within the document itself, which is time-consuming if you need to convert hundreds of notes.

To convert all notes at once you need to hack the text file, either by changing an fodt file's xml content, or by changing an odt file's `content.xml`. The latter two are automated by this script. Before running the script on an OpenDocument Text file, you should save the file, if you're currently working on it in LibreOffice Writer.

**Note:** If you just want LibreOffice Writer to *display* your footnotes at the end of your document without converting, you can do so by selecting the position "End of document" in the menu **Tools** > **Footnotes and Endnotes…**.

## Functionality
* one-shot conversion of all notes in a document (odt/fodt formats)
  * uses the `sed` command
  * only changes the `text-class` xml values
  * does not alter any style settings
* automatic footnote-to-endnote conversion, if document contains only footnotes
* automatic endnote-to-footnote conversion, if document contains only endnotes
* user prompt with three options, if document contains both footnotes and endnotes:
  1. merge all notes as endnotes
  2. merge all notes as footnotes
  3. swap footnotes <> endnotes
* original text file will not be touched
* creates new text file with suffix `-conv.odt` or `-conv.fodt`

## Planned functionality
* support for `docx` files (not sure if possible)

## Installation
* [Download the latest DMG](https://github.com/JayBrown/nnConv/releases) and open

### Workflow
* Double-click on the workflow file to install
* If you encounter problems, open it with Automator and save/install from there
* Standard Finder integration in the Services menu

### terminal-notifier [optional, recommended]
More information: [terminal-notifier](https://github.com/alloy/terminal-notifier)

You need to have Spotlight enabled for `mdfind` to locate the terminal-notifier.app on your volume; if you don't install terminal-notifier, or if you have deactivated Spotlight, nnConv will call notifications via AppleScript instead

#### Installation method #1
Install using [Homebrew](http://brew.sh) with `brew install terminal-notifier` (or with a similar manager)

#### Installation method #2
* move the terminal-notifier zip archive from the disk image to a folder on your main volume
* unzip the application and move it to a suitable location, e.g. to `/Applications`, `/Applications/Utilities`, or `$HOME/Applications`

### Shell script [optional]
Only necessary if for some reason you want to run this from the shell or another shell script. For normal use the workflow will be sufficient.

* Move the script `nn-conv.sh` into `/usr/local/bin`
* In your shell enter `chmod +x /usr/local/bin/nn-conv.sh`
* Run the script with `nn-conv.sh /path/to/target`

## Uninstall
Remove the following files or folders:

```
$HOME/Library/Caches/local.lcars.nnConv
$HOME/Library/Services/Convert All Notes.workflow
/usr/local/bin/nn-conv.sh
```
