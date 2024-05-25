module Input
  module FontStyle
    def self.from(word_chars:, font: nil, size_px: nil, size_enum: nil)
      font ||= ''
      return UsingSizePx.new(font: font, word_chars: word_chars, size_px: size_px) if size_px

      UsingSizeEnum.new(font: font, word_chars: word_chars, size_enum: size_enum)
    end

    class UsingSizeEnum
      attr_reader :font_height

      SIZE_ENUM = {
        small: -1,
        normal: 0,
        large: 1,
        xlarge: 2,
        xxlarge: 3,
        xxxlarge: 4
      }.freeze

      def initialize(font:,  word_chars:, size_enum:)
        @font = font
        @size_enum = SIZE_ENUM.fetch(size_enum || :normal, size_enum)
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
end
