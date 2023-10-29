module Input
  class TextValue
    attr_reader :text

    def initialize(text)
      @text = text
    end

    def to_s
      @text
    end

    def length
      @text.length
    end

    def empty?
      @text.empty?
    end

    def insert(from, to, text)
      @text = @text[0, from].to_s + text + @text[to, @text.length].to_s
    end

    def index(text)
      @text.index(text)
    end

    def rindex(text)
      @text.rindex(text)
    end

    def slice(from, length = 1)
      @text.slice(from, length)
    end
    alias [] slice

    def replace(text)
      @text = text
    end
  end

  class MultilineValue
    attr_reader :lines

    def initialize(text, word_wrap_chars, crlf_chars, font, size_enum, w)
      @w = w
      @line_parser = LineParser.new(word_wrap_chars, crlf_chars, font, size_enum)
      @lines = @line_parser.perform_word_wrap(text, @w)
    end

    def to_s
      @lines.text
    end

    def length
      @lines.last.end
    end

    def empty?
      @lines.last.end == 0
    end

    def insert(from, to, text) # rubocop:disable Metrics/AbcSize
      modified_lines = @lines.modified(from, to)
      original_value = modified_lines.text
      first_modified_line = modified_lines.first
      original_index = first_modified_line.start
      modified_value = original_value[0, from - original_index].to_s + text + original_value[to - original_index, original_value.length].to_s
      new_lines = @line_parser.perform_word_wrap(modified_value, @w, first_modified_line.number, original_index)

      @lines.replace(modified_lines, new_lines)
    end

    def index(text)
      @lines.text.index(text)
    end

    def rindex(text)
      @lines.text.rindex(text)
    end

    def slice(from, length = 1)
      @lines.text.slice(from, length)
    end
    alias [] slice

    def replace(text)
      @lines = @line_parser.perform_word_wrap(text, @w)
    end
  end
end
