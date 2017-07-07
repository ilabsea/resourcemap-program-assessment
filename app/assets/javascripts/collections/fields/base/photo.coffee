onCollections ->
  class @FieldPhoto
    @constructorFieldPhoto: (data) ->
      @photo = ''
      @photoPath = '/photo_field/'


    @fileSelected: (data, event) ->
      fileUploads = $("#" + data.code)[0].files
      if fileUploads.length > 0

        photoExt = fileUploads[0].name.split('.').pop()

        value = (new Date()).getTime() + "." + photoExt

        @value(value)

        reader = new FileReader()
        reader.onload = (event) =>
          @photo = event.target.result.split(',')[1]
          $("#imgUpload-" + @code).attr('src',event.target.result)
          $("#divUpload-" + @code).show()

        reader.readAsDataURL(fileUploads[0])
      else
        @photo = ''
        @value('')

    @removeImage: ->
      @photo = ''
      @value('')
      $("#" + @code).attr("value",'')
      $("#divUpload-" + @code).hide()
