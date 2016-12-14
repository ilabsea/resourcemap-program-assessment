$(document).ready(function() {
	var fontLists = "(ខ្មែរ)Khmer=khmer;"+
									"(ខ្មែរ)Khmer Moul=moul;"+
									"(ខ្មែរ)Hanuma=hanuman;"+
									"Andale Mono=andale mono,times;"+
									"Arial=arial,helvetica,sans-serif;"+
									"Arial Black=arial black,avant garde;"+
									"Book Antiqua=book_antiquaregular,palatino;"+
									"Corda Light=CordaLight,sans-serif;"+
									"Courier New=courier_newregular,courier;"+
									"Flexo Caps=FlexoCapsDEMORegular;"+
									"Lucida Console=lucida_consoleregular,courier;"+
									"Georgia=georgia,palatino;"+
									"Helvetica=helvetica;"+
									"Impact=impactregular,chicago;"+
									"Museo Slab=MuseoSlab500Regular,sans-serif;"+
									"Museo Sans=MuseoSans500Regular,sans-serif;"+
									"Oblik Bold=OblikBoldRegular;"+
									"Sofia Pro Light=SofiaProLightRegular;"+
									"Symbol=webfontregular;"+
									"Tahoma=tahoma,arial,helvetica,sans-serif;"+
									"Terminal=terminal,monaco;"+
									"Tikal Sans Medium=TikalSansMediumMedium;"+
									"Times New Roman=times new roman,times;"+
									"Trebuchet MS=trebuchet ms,geneva;"+
									"Verdana=verdana,geneva;"+
									"Webdings=webdings;"+
									"Wingdings=wingdings,zapf dingbats"+
									"Aclonica=Aclonica, sans-serif;"+
									"Michroma=Michroma;"+
									"Paytone One=Paytone One, sans-serif;"+
									"Andalus=andalusregular, sans-serif;"+
									"Arabic Style=b_arabic_styleregular, sans-serif;"+
									"Andalus=andalusregular, sans-serif;"+
									"KACST_1=kacstoneregular, sans-serif;"+
									"Mothanna=mothannaregular, sans-serif;"+
									"Nastaliq=irannastaliqregular, sans-serif";

	tinyMCE.init({
		height: 500,
		selector: 'textarea.custom-tinymce',
		plugins: [ 'preview print media image uploadimage table advlist autolink lists anchor',
							'fullscreen', 'insertdatetime table contextmenu paste code pagebreak'],
		toolbar: ["undo redo alignleft aligncenter alignright bold italic underline styleselect " +
							" fullscreen custom-insert-newpage paste copy | fontselect fontsizeselect table code "],
		font_formats:  fontLists,
		// valid_elements: "table tr td th tbody",
		setup: function (editor) {
	    editor.addButton('custom-insert-newpage', {
	      text: '',
				title: 'Insert New Page - Page break',
	      icon: 'pagebreak',
	      onclick: function () {
	        editor.insertContent('<p style="page-break-before: always;">&nbsp;<!-- pagebreak --></p>');
	      }
	    });
		}
	})
});
