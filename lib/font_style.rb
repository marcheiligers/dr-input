class FontStyle
  attr_reader :font_height

  def initialize(font:, size_enum:, word_chars:)
    @font = font
    @label_params = { size_enum: size_enum }
    _, @font_height = $gtk.calcstringbox(word_chars.join(''), font: @font, **@label_params)
  end

  def string_width(str)
    $gtk.calcstringbox(str, font: @font, **@label_params)[0]
  end

  def label(values)
    {
      font: @font,
      **@label_params,
      **values
    }
  end
end
