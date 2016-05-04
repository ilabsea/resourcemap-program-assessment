$(document).ready(function() {
	tinyMCE.init({
		width: 980,
		selector: 'textarea.custom-tinymce',
		plugins: [ 'table advlist autolink lists anchor', 'fullscreen', 'insertdatetime table contextmenu paste code pagebreak'],
		toolbar: "undo redo | alignleft aligncenter alignright bold italic underline styleselect table code fullscreen pagebreak"
	})
});
