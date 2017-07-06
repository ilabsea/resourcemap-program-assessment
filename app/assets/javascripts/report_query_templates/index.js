$(function(){
  $('#btn-generate-report').on('click', function(){
    templates = $('.templateList:checkbox:checked');
    if(templates.length > 0){
      $("#form-create-report").submit();
    }else{
      $.status.showError('Please select at least one report template to generate the report', 3000)
    }
  });
});
