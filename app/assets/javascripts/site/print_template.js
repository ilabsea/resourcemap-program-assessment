$(function(){
  $(".site-token").on('click', function() {
    var $this = $(this)
    var token = $this.text()
    insertIntoEditor(token)
  })
});
