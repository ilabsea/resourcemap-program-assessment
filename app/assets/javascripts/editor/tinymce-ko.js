ko.bindingHandlers.tinymce = {
    init: function (element, valueAccessor, allBindingsAccessor, context) {
        var options = allBindingsAccessor().tinymceOptions || {};
        var modelValue = valueAccessor();

        //handle edits made in the editor
        options.skins = "lightgray-gradient"
        // options.statusbar = false
        options.plugins = [ 'table advlist autolink lists link anchor',
                           'fullscreen',
                           'insertdatetime table contextmenu paste code']
        options.menubar =  false
        options.toolbar = "alignleft aligncenter table styleselect bold fullscreen"

        options.setup = function (editor) {
          editor.on('focus', function(e){
            console.log("focus", editor)
            window.activeEditor = editor
            // window.activeEditor.execCommand('mceInsertContent', false, "some text")
          })

          editor.on('change', function(e) {
             console.log('the content '+ editor.getContent());
             if (ko.isWriteableObservable(modelValue)) {
                 modelValue(editor.getContent());
             }
          });

          editor.on('blur', function (e) {
            if (ko.isWriteableObservable(modelValue)) {
                modelValue(editor.getContent());
            }
          });
        };

        //handle destroying an editor (based on what jQuery plugin does)
        ko.utils.domNodeDisposal.addDisposeCallback(element, function () {
            $(element).parent().find("span.mceEditor,div.mceEditor").each(function (i, node) {
                var ed = tinyMCE.get(node.id.replace(/_parent$/, ""));
                if (ed) {
                    ed.remove();
                }
            });
        });

        //$(element).tinymce(options);
        setTimeout(function() { window.activeEditor = $(element).tinymce(options); }, 0);

    },
    update: function (element, valueAccessor, allBindingsAccessor, context) {
        //handle programmatic updates to the observable
        var value = ko.utils.unwrapObservable(valueAccessor());
        $(element).html(value);
    }
};

tinyMCE.init({
  // skin_url: '/assets/tinymce/skins/custom/'
  menubar: false,
  statusbar: false,
  toolbar: false,
  skin: "lightgray-gradient",
  table_toolbar: ""
});

tinymce.init({
        themes: "modern",
        table_toolbar: "",
        plugins: [
            "advlist autolink lists link image charmap print preview anchor",
            "searchreplace visualblocks code fullscreen",
            "insertdatetime media table contextmenu paste"
        ],
        toolbar: "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image"
    });
