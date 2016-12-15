function generatePdf(){
  $('.templateList:checkbox:checked').each(function () {
    console.log($(this).val());
  });
}
