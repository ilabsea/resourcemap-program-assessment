function insertIntoEditor(token) {
  tinymce.activeEditor.execCommand("mceInsertContent", false, token)
}
