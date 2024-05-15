class FontStyle
  attr_reader :font_height

  def initialize(font:, size_enum:, word_chars:)
    @font = font
    @size_enum = size_enum
    _, @font_height = $gtk.calcstringbox(word_chars.join(''), @size_enum, @font)
  end

  def string_width(str)
    $gtk.calcstringbox(str, @size_enum, @font)[0]
  end
end
