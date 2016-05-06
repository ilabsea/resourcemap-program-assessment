class SitePrintTemplate

  def initialize(site)
    @site = site
    @values = {
      "[Site Name]" => @site.name,
      "[Creator]" => @site.user.email,
      "[Lat]" => @site.lat,
      "[Lng]" => @site.lng
    }
    @fields = @site.collection.fields
  end

  def translate
    template = @site.collection.print_template
    return "" if template.blank?
    template.gsub /(\[[^\]]*\])|(\{[^\}]*\})/mu do |matched|
      parse(matched)
    end
  end

  def parse(matched)
    return @values[matched] if @values[matched]
    field_code = matched[1..-2]

    @fields.each do |field|
      if field.code == field_code
        result = @site.properties["#{field.id}"]
        return '' if (field.is_custom_aggregator && result == 0)
        return result
      end
    end
    return matched
  end
end
