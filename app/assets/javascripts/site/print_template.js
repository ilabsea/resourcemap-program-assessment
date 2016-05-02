$(function(){
  $(".site-token").on('click', function() {
    var $this = $(this)
    var token = $this.text()
    tinymce.activeEditor.execCommand('mceInsertContent', false, token);

  })
});
