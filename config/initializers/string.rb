class String
  # Does this string represent an integer?
  def integer?
    Integer(self) rescue nil
  end

  def real?
    Float(self) rescue nil
  end

  def interpolate(option_hash)
    self.gsub(/\[[\w\s()]+\]/) do |template|
      has_value = false
      option_hash.each do |key, value|
        if template == '['+ key+ ']'
          template = value
          has_value = true
          break
        end
      end
      template = '' if has_value == false
      template
    end
  end

end
