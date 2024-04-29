module Input
  class RubyParser
    # def initialize
    #   @state = :whitespace
    #   @tokens = []
    #   @stack = []
    #   @token = ''
    # end

    TOKEN_TYPES = {
      whitespace: 0x000000,
      numeric: :int,
      int: 0x000000,
      dot: 0x000000,
      float_or_method_call: :error,
      hex: :int,
      oct: :int,
      error: 0xFF0000,
      float: 0x000000,
      method_call: 0x000000,
      keyword: 0x000000,
    }

    # --- Unhandled types ---
    # TODO: single quoted strings
    # TODO: double quoted strings
    # TODO: double quoted string interpolation
    # TODO: heredocs
    # TODO: heredocs string interpolation
    # TODO: heredocs containing heredocs :/
    # TODO: syscalls `ls`
    # TODO: escaped characters

    # TODO: CONSTANTS
    # TODO: Modules and Classes
    # TODO: reserved keywords
    # TODO: Basic object methods

    def parse(str)
      l = str.length
      i = -1
      token = ''
      tokens = []
      state = :whitespace
      stack = []

      while (i += 1) < l
        ch = str[i]
        puts "#{state} #{stack}"
        case state
        when :whitespace
          if whitespace?(ch)
            token << ch
          elsif number?(ch)
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            state = :numeric
            token = ch
          elsif char?(ch) || ch == '_'
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            state = :keyword
            token = ch
          elsif bracket?(ch)
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            token = ch
            state = :bracket
          elsif operator?(ch)
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            token = ch
            state = :operator
          elsif ch == '#'
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            token = ch
            state = :comment
          elsif ch == '@'
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            token = ch
            state = :instance_var
          elsif ch == '$'
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            token = ch
            state = :global_var
          elsif ch == ':'
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            token = ch
            state = :symbol
          elsif ch == '"'
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            token = ch
            state = :double_quoted_str
          else
            tokens << Token.at(token, :whitespace, i) if token.length > 0
            token = ch
            state = :error
          end
        when :double_quoted_str
          if ch == '"'
            tokens << Token.at(token + ch, :double_quoted_str, i + 1)
            token = ''
            state = :whitespace
          elsif ch == '\\'
            tokens << Token.at(token, :double_quoted_str, i)
            token = ch
            state = :escape_char
          elsif ch == '#' && str[i + 1] == '{'
            tokens << Token.at(token, :double_quoted_str, i) << Token.at('#{', :interpolation, i + 2)
            token = ''
            state = :whitespace
            stack << :interpolation
            i += 1
          else
            token << ch
          end
        when :escape_char
          tokens << Token.at(token + ch, :escape_char, i + 1)
          token = ''
          state = :double_quoted_str
        when :numeric
          if ch == '.'
            tokens << Token.at(token, :int, i) << Token.at(ch, :dot, i + 1)
            token = ''
            state = :float_or_method_call
          elsif token == '0' && ch == 'x'
            state = :hex
            token << ch
          elsif token == '0' && oct?(ch)
            state = :oct
            token << ch
          elsif number?(ch) || ch == '_'
            token << ch
            state = :int
          elsif whitespace?(ch)
            tokens << Token.at(token, :int, i)
            token = ch
            state = :whitespace
          else
            tokens << Token.at(token, :int, i)
            token = ch
            state = :error
          end
        when :int
          if ch == '.'
            tokens << Token.at(token, :int, i) << Token.at(ch, :dot, i + 1)
            token = ''
            state = :float_or_method_call
          elsif number?(ch) || ch == '_'
            token << ch
          elsif bracket?(ch)
            tokens << Token.at(token, :int, i)
            token = ch
            state = :bracket
          elsif operator?(ch)
            tokens << Token.at(token, :int, i)
            token = ch
            state = :operator
          elsif whitespace?(ch)
            tokens << Token.at(token, :int, i)
            token = ch
            state = :whitespace
          else
            tokens << Token.at(token, :int, i)
            token = ch
            state = :error
          end
        when :float_or_method_call # if we get here, we have an :int followed by a :dot, and token is empty
          if number?(ch)
            token = ch
            state = :float
          elsif char?(ch)
            token = ch
            state = :method_call
          else
            token = ch
            state = :error
          end
        when :float
          if number?(ch) || ch == '_'
            token << ch
          elsif ch == '.'
            tokens << Token.at(token, :float, i) << Token.at(ch, :dot, i + 1)
            token = ''
            state = :method_call
          else
            token << ch
            state = :error
          end
        when :hex
          if hex?(ch)
            token << ch
          elsif ch == '.'
            tokens << Token.at(token, :int, i) << Token.at(ch, :dot, i + 1)
            token = ''
            state = :method_call
          else
            tokens << Token.at(token, :int, i)
            token = ch
            state = :error
          end
        when :oct
          if oct?(ch)
            token << ch
          elsif ch == '.'
            tokens << Token.at(token, :float, i) << Token.at(ch, :dot, i + 1)
            token = ''
            state = :method_call
          else
            tokens << Token.at(token, :oct, i)
            token = ch
            state = :error
          end
        when :instance_var, :global_var, :keyword, :symbol # TODO: symbols can be quoted strings
          if char?(ch) || ch == '_' || number?(ch)
            token << ch
          elsif bracket?(ch)
            tokens << Token.at(token, state, i)
            token = ch
            state = :bracket
          elsif operator?(ch)
            tokens << Token.at(token, state, i)
            token = ch
            state = :operator
          elsif whitespace?(ch)
            tokens << Token.at(token, state, i)
            token = ch
            state = :whitespace
          elsif ch == ':' && state == :keyword
            tokens << Token.at(token + ':', :symbol, i + 1)
            token = ''
            state = :whitespace
          else
            tokens << Token.at(token, state, i)
            token = ch
            state = :error
          end
        when :method_call
          if token.length == 0 && number?(ch)
            token << ch
            state = :error
          elsif char?(ch) || ch == '_' || number?(ch)
            token << ch
          elsif bracket?(ch)
            tokens << Token.at(token, :method_call, i)
            token = ch
            state = :bracket
          elsif operator?(ch)
            tokens << Token.at(token, :method_call, i)
            token = ch
            state = :operator
          elsif whitespace?(ch)
            tokens << Token.at(token, :method_call, i)
            token = ch
            state = :whitespace
          else
            tokens << Token.at(token, :method_call, i)
            token = ch
            state = :error
          end
        when :operator
          if whitespace?(ch)
            tokens << Token.at(token, :operator, i)
            token = ch
            state = :whitespace
          elsif token.length < 2 && operator?(ch)
            token << ch
          elsif bracket?(ch)
            tokens << Token.at(token, :operator, i)
            token = ch
            state = :bracket
          elsif number?(ch)
            tokens << Token.at(token, :operator, i)
            state = :numeric
            token = ch
          elsif char?(ch) || ch == '_'
            tokens << Token.at(token, :operator, i)
            state = :keyword
            token = ch
          else
            tokens << Token.at(token, :operator, i)
            state = :error
            token = ch
          end
        when :bracket
          stack << :brace if token == '{' # we keep track of braces because it's possible to use blocks or hashes in interpolation

          if token == '}'
            if stack.last == :interpolation
              tokens << Token.at(token, :interpolation, i)
              state = :double_quoted_str
            else
              tokens << Token.at(token, :bracket, i)
            end
            token = ''
            stack.pop
          end

          if whitespace?(ch)
            tokens << Token.at(token, :bracket, i)
            token = ch
            state = :whitespace
          elsif token.length == 1 && bracket?(ch) # Brackets are always singular, so we can try do color matching
            tokens << Token.at(token, :bracket, i) # TODO: keep a stack of brackets for matching?
            token = ch
            state = :bracket
          elsif operator?(ch)
            tokens << Token.at(token, :bracket, i)
            token = ch
            state = :operator
          elsif number?(ch)
            tokens << Token.at(token, :bracket, i)
            state = :numeric
            token = ch
          elsif char?(ch) || ch == '_'
            tokens << Token.at(token, :bracket, i)
            state = :keyword
            token = ch
          else
            tokens << Token.at(token, :bracket, i)
            state = :error
            token << ch
          end
        when :comment
          token << ch
        when :error
          if whitespace?(ch)
            tokens << Token.at(token, :error, i)
            token = ch
            state = :whitespace
          elsif operator?(ch)
            tokens << Token.at(token, :error, i)
            token = ch
            state = :operator
          elsif bracket?(ch)
            tokens << Token.at(token, :error, i)
            token = ch
            state = :bracket
          else
            token << ch
          end
        end
      end

      type = TOKEN_TYPES[state]
      tokens << Token.at(token, type.is_a?(Symbol) ? type : state, i) if token.length > 0
      tokens
    end

    def parse2(str)
      l = str.length
      i = -1
      token = ''
      tokens = []
      state = :start
      stack = []

      while (i += 1) < l
        ch = str[i]
        case state
        when :start
          if whitespace?(ch)
            token = ch
            state = :whitespace
          elsif ch == '"'
            token = ch
            stack << state = :double_quoted_str
          elsif ch == '{'
            tokens << Token.at(ch, :bracket, i)
            stack << :brace
          end
        when :whitespace
          if whitespace?(ch)
            token << ch
          else # reset and go back to :start
            tokens << Token.at(token, :whitespace, i)
            token = ''
            i -= 1
            state = :start
          end
        when :double_quoted_str
        when :numeric
        when :keyword
        end
      end
    end

    SPLITS_TOKENS = '[](){}+-=*/&*^|%!<>.'
    def split?(ch)
      SPLITS_TOKENS.include?(ch)
    end

    def whitespace?(ch)
      ch.strip == ''
    end

    NUMBERS = '1234567890'
    def number?(ch)
      NUMBERS.include?(ch)
    end

    OCT_NUMBERS = '12345670'
    def oct?(ch)
      OCT_NUMBERS.include?(ch)
    end

    HEX_NUMBERS = '1234567890ABCDEFabcdef'
    def hex?(ch)
      HEX_NUMBERS.include?(ch)
    end

    BRACKETS = '[](){}'
    def bracket?(ch)
      BRACKETS.include?(ch)
    end

    LOWER_CHARS = ('a'..'z').to_a.join('')
    UPPER_CHARS = ('A'..'Z').to_a.join('')
    def char?(ch)
      LOWER_CHARS.include?(ch) || UPPER_CHARS.include?(ch)
    end

    OPERATORS = '+-=*/&*^|%!<>'
    def operator?(ch)
      OPERATORS.include?(ch)
    end
  end

  class Token
    attr_reader :token, :type, :position

    def self.at(token, type, end_position)
      new(token, type, end_position - token.length)
    end

    def initialize(token, type, position)
      @token = token
      @type = type
      @position = position
    end

    def ==(other)
      @token == other.token && @type == other.type && @position == other.position
    end

    def to_s
      token
    end

    def inspect
      "<#Token:#{@type}@#{@position} #{@token}>"
    end
  end
end
