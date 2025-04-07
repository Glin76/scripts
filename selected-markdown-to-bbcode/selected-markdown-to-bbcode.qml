import QtQml 2.0

/**
 * This script creates a menu item and a button that converts the selected Markdown
 * text to BBCode in the clipboard
 *
 * Dependencies:
 * http://pandoc.org
 * https://github.com/2ion/pandoc-bbcode
 */
QtObject {
    property string pandocPath

    // the path to the script's directory will be set here
    property string scriptDirPath

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [
        {
            "identifier": "pandocPath",
            "name": "Pandoc path",
            "description": "Please select the path to your Pandoc executable:",
            "type": "file",
            "default": "pandoc"
        },
    ]

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier != "markdownToBBCode") {
            return;
        }

        // get the selected text from the note text edit
        var text = script.noteTextEditSelectedText();

        // get the path of the lua script
        var panbbcodePath = scriptDirPath + script.dirSeparator() + "panbbcode.lua";

        // you need pandoc and the BBCode writer from https://github.com/2ion/pandoc-bbcode
        // to convert Markdown to BBCode
        var params = ["-t", panbbcodePath, "-f", "markdown"];
        var result = script.startSynchronousProcess(pandocPath, params, text);

        // do some code list cleanup
        result = replaceAll(result, "[list=*]", "[list]");
        result = replaceAll(result, "[/*]", "");

        // convert inline code blocks to italic
        // do this 10 times to take care of multiple code blocks in a line
        for (var i = 0; i < 10; i++) {
            result = result.replace(/^(.+?)\[code\](.+?)\[\/code\]/img, "$1[i]$2[/i]");
        }

        // convert headlines to bold
        result = replaceAll(result, "[h]", "[b]");
        result = replaceAll(result, "[/h]", "[/b]");

        // convert `em` to `i`
        result = replaceAll(result, "[em]", "[i]");
        result = replaceAll(result, "[/em]", "[/i]");

        // link some users
        result = replaceAll(result, "@Georg", "[USER=1]Georg[/USER]");
        result = replaceAll(result, "@Sören", "[USER=2]Sören[/USER]");
        result = replaceAll(result, "@Robert", "[USER=16]Robert[/USER]");
        result = replaceAll(result, "@Stephan", "[USER=8]Stephan[/USER]");
        result = replaceAll(result, "@Gunnar", "[USER=14]Gunnar[/USER]");

        // put the result into the clipboard
        script.setClipboardText(result);
    }
    function escapeRegExp(str) {
        return str.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");
    }

    /**
     * Initializes the custom action
     */
    function init() {
        script.registerCustomAction("markdownToBBCode", "Markdown to BBCode", "BBCode", "edit-copy", true, true);
    }
    function replaceAll(str, find, replace) {
        return String(str).replace(new RegExp(escapeRegExp(find), 'gi'), replace);
    }
}
