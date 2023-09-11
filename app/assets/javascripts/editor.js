//= require activeadmin/quill_editor/quill
//= require activeadmin/quill_editor_input

const Delta = Quill.import("delta");
const Break = Quill.import("blots/break");
const Embed = Quill.import("blots/embed");
const Keyboard = Quill.import("modules/keyboard");
const Clipboard = Quill.import("modules/clipboard");

Keyboard.DEFAULTS["bindings"]["linebreak"] = {
  key: 13,
  shiftKey: true,
  handler: function(range, context) {
    const currentLeaf = this.quill.getLeaf(range.index)[0];
    const nextLeaf = this.quill.getLeaf(range.index + 1)[0];

    this.quill.insertEmbed(range.index, "break", true, "user");
    // Insert a second break if:
    // At the end of the editor, OR next leaf has a different parent (<p>)
    if (nextLeaf === null || currentLeaf.parent !== nextLeaf.parent) {
      this.quill.insertEmbed(range.index, "break", true, "user");
    }
    // Now that we've inserted a line break, move the cursor forward
    this.quill.setSelection(range.index + 1, Quill.sources.SILENT);
  }
}

class ExtendedClipboard extends Clipboard {
  constructor(quill, options) {
    super(quill, options);

    this.addMatcher("BR", function(node, delta) {
      let newDelta = new Delta();
      newDelta.insert({ break: "" });
      return newDelta;
    });
  }
}

class SmartBreak extends Break {
  length() {
    return 1;
  }
  value() {
    return "\n";
  }

  insertInto(parent, ref) {
    Embed.prototype.insertInto.call(this, parent, ref);
  }
}

SmartBreak.blotName = "break";
SmartBreak.tagName = "BR";

Quill.register("modules/clipboard", ExtendedClipboard, true);
Quill.register(SmartBreak);
