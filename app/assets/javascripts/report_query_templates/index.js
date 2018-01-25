$(function(){
  $('#btn-generate-report').on('click', function(){
    templates = $('.templateList:checkbox:checked');
    if(templates.length > 0){
      $("#form-create-report").submit();
    }else{
      $.status.showError(window.t("javascripts.report_queries.at_least_one_report_template"), 3000)
    }
  });
});
