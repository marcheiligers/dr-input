module FontStyle
  def self.from(**params)
    return UsingSizePx.new(**params) if params[:size_px]

    UsingSizeEnum.new(**params)
  end

  class UsingSizeEnum
    attr_reader :font_height

    def initialize(font:,  word_chars:, size_enum:)
      @font = font
      @size_enum = size_enum
      _, @font_height = $gtk.calcstringbox(word_chars.join(''), @size_enum, @font)
    end

    def string_width(str)
      $gtk.calcstringbox(str, @size_enum, @font)[0]
    end

    def label(values)
      { font: @font, size_enum: @size_enum, **values }
    end
  end

  class UsingSizePx
    attr_reader :font_height

    def initialize(font:,  word_chars:, size_px:)
      @font = font
      @size_px = size_px
      _, @font_height = $gtk.calcstringbox(word_chars.join(''), font: @font, size_px: @size_px)
    end

    def string_width(str)
      $gtk.calcstringbox(str, font: @font, size_px: @size_px)[0]
    end

    def label(values)
      { font: @font, size_px: @size_px, **values }
    end
  end
end
