import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
    property string classPrefix
    property string commentsAdditionColor
    property string commentsBackgroundColor
    property string commentsDeletionColor
    property string commentsHightlightsColor
    property variant settingsVariables: [
        {
            "identifier": "classPrefix",
            "name": "Prefix for HTML tags' class",
            "description": "Set the HTML tags' classes for the prefix of Critic Markup",
            "type": "string",
            "default": "critic_markup_"
        },
        {
            "identifier": "commentsBackgroundColor",
            "name": "Comments Background Color",
            "description": "Color for the backgroud of the Critc Markup comments (name or #hex):",
            "type": "string",
            "default": "#FFFF00"
        },
        {
            "identifier": "commentsHightlightsColor",
            "name": "Hightlights Border Color",
            "description": "Color for the hightlights in Critc Markup (name or #hex):",
            "type": "string",
            "default": "#ff832b"
        },
        {
            "identifier": "commentsDeletionColor",
            "name": "Deletions Text Color",
            "description": "Color for the deleted text in Critc Markup (name or #hex):",
            "type": "string",
            "default": "#FF0000"
        },
        {
            "identifier": "commentsAdditionColor",
            "name": "Addition Text Color",
            "description": "Color for the added text in Critc Markup (name or #hex):",
            "type": "string",
            "default": "#008000"
        }
    ]

    function customActionInvoked(identifier) {
        switch (identifier) {
        case "tranformToCMComments":
            // getting selected text from the note text edit
            var text = "{>>" + script.noteTextEditSelectedText() + "<<}";
            // put the result to the current cursor position in the note text edit
            script.noteTextEditWrite(text);
            break;
        case "tranformToCMAdded":
            // getting selected text from the note text edit
            var text = "{++" + script.noteTextEditSelectedText() + "++}";
            // put the result to the current cursor position in the note text edit
            script.noteTextEditWrite(text);
            break;
        case "tranformToCMDeleted":
            // getting selected text from the note text edit
            var text = "{--" + script.noteTextEditSelectedText() + "--}";
            // put the result to the current cursor position in the note text edit
            script.noteTextEditWrite(text);
            break;
        case "tranformToCMSubstitute":
            // getting selected text from the note text edit
            var text = "{~~" + script.noteTextEditSelectedText() + "~> NEWTEXT ~~}";
            // put the result to the current cursor position in the note text edit
            script.noteTextEditWrite(text);
            break;
        case "tranformToCMHighlighted":
            // getting selected text from the note text edit
            var text = "{==" + script.noteTextEditSelectedText() + "==}{>> COMMENTS <<}";
            // put the result to the current cursor position in the note text edit
            script.noteTextEditWrite(text);
            break;
        }
    }
    function init() {
        script.registerCustomAction("tranformToCMComments", "Transform the text to comment with Critic Markup", "Transform the text to comment with Critic Markup", "edit-comment");
        script.registerCustomAction("tranformToCMAdded", "Mark the text as added with Critic Markup", "Mark the text as added with Critic Markup", "list-add");
        script.registerCustomAction("tranformToCMDeleted", "Mark the text as deleted with Critic Markup", "Mark the text as deleted with Critic Markup", "list-remove");
        script.registerCustomAction("tranformToCMSubstitute", "Substitute the text with Critic Markup", "Substitute the text with Critic Markup", "entry-edit");
        script.registerCustomAction("tranformToCMHighlighted", "Hightlight the text with Critic Markup", "Hightlight the text with Critic Markup", "edit-comment");
    }
    /**
	 * This function is meant to wrap content with Critic Markup correctly
	 *
	 * It wrap HTML specific Critic Markup tags INSIDE other HTML tags.
	 *
	 * Ex. This text:
	 * {--<p>This is a </p><p>multiline example</p>--}
	 * Will render
	 * <p><del>This is a </del></p><p><del>mutliline example</del></p>
	 *
	 * @param {string} tag - tag name used for the replacement (if the tag should have a specific class(es) use "tag class='class1 class2". The unclosed quotes are intentional)
	 * @param {string} caught -  whole caught string (not used at the moment)
	 * @param {string} preTags - tags caught just before the Critic Markup
	 * @param {string} content - matched string to wrap Critic Markup
	 * @return {string} the modified content with  Critic Markup wraped INSIDE HTML Tags
	 */
    function nestTags(tag, caught, preTags, content) {
        var tagOpen = classPrefix + script.getPersistentVariable("criticMarkup/classNum", 0) + "'>";
        if (tag.match(/class='/g)) {
            tagOpen = "<" + tag + " " + tagOpen;
            tag = tag.replace(/ class='(?:[\s\S]*?)$/g, "");
        } else {
            tagOpen = "<" + tag + " class='" + classPrefix + script.getPersistentVariable("criticMarkup/classNum", 0) + "'>";
        }
        preTags = preTags + tagOpen;
        content = content.replace(/<\/(\w+?>)/gm, "</" + tag + "></$1");
        content = content.replace(/<(\w+?>)/gm, "<$1" + tagOpen);
        var toReturn = preTags + content + "</" + tag + ">";
        return toReturn;
    }
    /**
     * This function is called when the markdown html of a note is generated
     *
     * It allows you to modify this html
     * This is for example called before by the note preview
     *
     * The method can be used in multiple scripts to modify the html of the preview
     *
     * @param {NoteApi} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @param {string} forExport - the html is used for an export, false for the preview
     * @return {string} the modified html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html, forExport) {

        // Resetting the critic markups' counter
        script.setPersistentVariable("criticMarkup/classNum", 0);

        // replace {~~something~>\n\n~~}
        // to <del class='critic_markup_##'>something</del></p><ins class="break critic_markup_##">&nbsp;</ins><p>
        // FIXME [\s\S] si too greedy (because of the spaces ???) and get everything until the last ~&gt;
        // html = html.replace(/((?:<\w+?>)*?)\{(?:<s>|~~)([\s\S]+?)~&gt;((?:\s*?(?:<\/p>\s*?<p>))+?)(?:<\/s>|~~)\}/, wrapReplacementsByPIntoTags);

        // replace {~~something~>something else~~}
        // to <del class='critic_markup_##'>something</del><ins class='critic_markup_##'>something else</ins>
        html = html.replace(/((?:<\w+?>)*?)\{(?:<s>|~~)([\s\S]+?)~&gt;([\s\S]*?)(?:<\/s>|~~)\}/gm, wrapReplacementsIntoTags);

        // replace {==something==}{>>something else<<}
        // to <mark class='critic_markup_##'>something</mark><span class='critic comment critic_markup_##'>something else</span>
        html = html.replace(/((?:<\w+?>)*?)\{(?:<mark>|==)([\s\S]+?)(?:<\/mark>|==)\}\{(?:&gt;&gt;|>>)([\s\S]*?)(?:&lt;&lt;|<<)\}/gm, wrapHightlightsIntoTags);

        // replace {>>something<<} to <span class='critic comment critic_markup_##'>something</span>
        html = html.replace(/((?:<\w+?>)*?)\{(?:&gt;&gt;|>>)([\s\S]+?)(?:&lt;&lt;|<<)\}/gm, wrapComsIntoTags);

        // replace {++\n\n++} to </p><ins class='break'>&nbsp;</ins><p>
        html = html.replace(/\{\+\+(?:\s*?)((?:<\/p>\s*?<p>)+?)\+\+\}/gm, "</p>\n\n<ins class='break'>&nbsp;</ins>\n\n<p>");

        // replace {++something++} to <ins class='critic_markup_##'>something</ins>
        html = html.replace(/((?:<\w+?>)*?)\{\+\+([\s\S]+?)\+\+\}/gm, wrapInsIntoTags);

        // replace {--\n\n--} to <del>&nbsp;</del>
        html = html.replace(/\{\-\-(?:\s*?(?:<\/p>\s*?<p>))+?\-\-\}/gm, "<del>&nbsp;</del>");

        // replace {--something--} to <del class='critic_markup_##'>something</del>
        html = html.replace(/((?:<\w+?>)*?)\{\-\-([\s\S]+?)((?:<\w+?>)*?)\-\-\}/gm, wrapDelIntoTags);

        // Setting the styles for the preview
        var stylesheet = "span.critic.comment, span.critic.metadata {background-color:" + commentsBackgroundColor + "; padding-left: 4px; border-left: 4px solid " + commentsHightlightsColor + "; } del {color: " + commentsDeletionColor + " ; text-decoration: line-through;} ins {color: " + commentsAdditionColor + " ; text-decoration: underline;} ins.break {background-color: " + commentsAdditionColor + "} mark {background-color:" + commentsHightlightsColor + ";}";

        html = html.replace("</style>", stylesheet + "</style>");
        return html;
    }
    function wrapComsIntoTags(caught, preTags, content) {
        // Increments the markup class number
        script.setPersistentVariable("criticMarkup/classNum", script.getPersistentVariable("criticMarkup/classNum", 0) + 1);
        return nestTags("span class='critic comment", caught, preTags, content);
    }
    function wrapDelIntoTags(caught, preTags, content) {
        // Increments the markup class number
        script.setPersistentVariable("criticMarkup/classNum", script.getPersistentVariable("criticMarkup/classNum", 0) + 1);
        return nestTags("del", caught, preTags, content);
    }
    function wrapHightlightsIntoTags(caught, preTags, content, comments) {
        script.setPersistentVariable("criticMarkup/classNum", script.getPersistentVariable("criticMarkup/classNum", 0) + 1);
        var toReturn = nestTags("mark", caught, preTags, content);
        toReturn = toReturn + nestTags("span class='critic metadata", caught, "", comments);
        return toReturn;
    }
    function wrapInsIntoTags(caught, preTags, content) {
        // Increments the markup class number
        script.setPersistentVariable("criticMarkup/classNum", script.getPersistentVariable("criticMarkup/classNum", 0) + 1);
        return nestTags("ins", caught, preTags, content);
    }
    function wrapReplacementsByPIntoTags(caught, preTags, del, ins) {
        // Increments the markup class number
        script.setPersistentVariable("criticMarkup/classNum", script.getPersistentVariable("criticMarkup/classNum", 0) + 1);
        var toReturn = nestTags("del", caught, preTags, del);
        toReturn = toReturn + '\n\n</p><ins class="break' + classPrefix + script.getPersistentVariable("criticMarkup/classNum", 0) + '">&nbsp;</ins>\n\n<p>';
        return toReturn;
    }
    function wrapReplacementsIntoTags(caught, preTags, del, ins) {
        // Increments the markup class number
        script.setPersistentVariable("criticMarkup/classNum", script.getPersistentVariable("criticMarkup/classNum", 0) + 1);
        var toReturn = nestTags("del", caught, preTags, del);
        toReturn = toReturn + nestTags("ins", caught, "", ins);
        return toReturn;
    }
}
