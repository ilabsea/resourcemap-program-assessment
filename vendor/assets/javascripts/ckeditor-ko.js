ko.bindingHandlers.rev_ckeditor = {
    init: function (element, valueAccessor, allBindingsAccessor, context, review) {
        var $element   = $(element);
        var observable = valueAccessor();

        var editor = CKEDITOR.replace(element);

        ko.computed(function() {
          editor.setData( observable());
        }, { disposeWhenNodeIsRemoved: element });

        jQuery.fn.cke_resize = function () {
            return this.each(function () {
                var $this = $(this);
                var rows = $this.attr('rows');
                var height = rows * 20;
                $this.next("div.cke").find(".cke_contents").css("height", height);
            });
        };

        CKEDITOR.on('instanceReady', function () {
            $element.cke_resize();
        });

        editor.on('focus', function(e){
          console.log("focus", e.editor)
        })

        editor.on('blur', function (e) {
          console.log("blur", e.editor)
          if (ko.isWriteableObservable(observable)) {
              observable(e.editor.getData());
          }
        });
    }
};

$(function(){
  $('.ckeditor').ckeditor();
})
