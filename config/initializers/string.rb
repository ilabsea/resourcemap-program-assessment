class String
  # Does this string represent an integer?
  def integer?
    Integer(self) rescue nil
  end

  def real?
    Float(self) rescue nil
  end

  def render_template_string(option_hash)
    self.gsub(/\[[\w\s()]+\]/) do |template|
      has_value = true
      option_hash.each do |key, value|
        if template == '['+ key+ ']'
          if key == "Site Name"
            template = value
          else
            template = value
          end
          has_value = true
          break
        else
          has_value = false
        end
      end
      template = '' if has_value == false
      template
    end
  end

end
