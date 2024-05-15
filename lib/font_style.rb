class FontStyle
  attr_reader :font_height

  def initialize(font:, size_enum:, word_chars:)
    @font = font
    @size_enum = size_enum
    _, @font_height = $gtk.calcstringbox(word_chars.join(''), @size_enum, @font)
  end
end
