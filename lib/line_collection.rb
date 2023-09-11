module Input
  class LineCollection
    attr_reader :text_length

    include Enumerable

    class Line
      attr_reader :number, :text, :clean_text, :start, :end, :length, :wrapped, :new_line

      def initialize(number, start, text, wrapped, font, size_enum)
        @number = number
        @start = start
        @text = text
        @clean_text = text.delete_prefix("\n")
        @length = text.length
        @end = start + @length
        @wrapped = wrapped
        @new_line = text[0] == "\n"
        @font = font
        @size_enum = size_enum
      end

      def wrapped?
        @wrapped
      end

      def new_line?
        @new_line
      end

      def to_s
        @text
      end

      def inspect
        "<Line##{@number} #{@start},#{@length} #{@text.gsub("\n", '\n')[0, 20]} #{@wrapped ? '\r' : '\n'}>"
      end

      def measure_to(index)
        if @text[0] == "\n"
          index < 1 ? 0 : $gtk.calcstringbox(@text[1, index - 1], @size_enum, @font)[0]
        else
          $gtk.calcstringbox(@text[0, index], @size_enum, @font)[0]
        end
      end

      def index_at(x)
        return @start if x <= 0

        index = -1
        width = 0
        while (index += 1) < length
          char = @text[index, 1]
          char_w = char == "\n" ? 0 : $gtk.calcstringbox(char, @size_enum, @font)[0]
          # TODO: Test `index_at` with multiple different fonts
          char_mid = char_w / 4
          return index + @start if width + char_mid > x
          return index + 1 + @start if width + char_mid > x

          width += char_w
        end

        index + @start
      end
    end

    def initialize(font, size_enum)
      @lines = []
      @text_length = 0
      @font = font
      @size_enum = size_enum
    end

    def each
      @lines.each { |line| yield(line) }
    end

    def length
      @lines.length
    end

    def [](num)
      @lines[num]
    end

    def append(text, wrapped = false)
      @lines.append(Line.new(@lines.length, @lines.last&.end.to_i, text, wrapped, @font, @size_enum))
      @text_length += text.length
      self
    end

    def <<(text)
      append(text)
    end

    def line_at(index)
      @lines.detect { |line| index <= line.end } || @lines.last
    end
  end
end
