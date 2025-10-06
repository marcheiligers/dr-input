require 'lib/parser.rb'

module Input
  class RubyText < Text
    DEFAULT_THEME = {
      keyword: { r: 197, g: 134, b: 192 },      # Purple
      string: { r: 152, g: 195, b: 121 },       # Green
      number: { r: 209, g: 154, b: 102 },       # Orange
      comment: { r: 92, g: 99, b: 112 },        # Gray
      symbol: { r: 86, g: 182, b: 194 },        # Cyan
      constant: { r: 229, g: 192, b: 123 },     # Yellow
      identifier: { r: 224, g: 224, b: 224 },   # White
      operator: { r: 171, g: 178, b: 191 },     # Light gray
      global: { r: 224, g: 108, b: 117 },       # Red
      interpolation_start: { r: 152, g: 195, b: 121 },  # Green
      interpolation_end: { r: 152, g: 195, b: 121 },    # Green
      array_literal: { r: 152, g: 195, b: 121 } # Green
    }.freeze

    def initialize(**params)
      custom_theme = params.delete(:theme) || {}
      theme = DEFAULT_THEME.merge(custom_theme)
      @theme = theme.transform_values { |color| color.merge(vertical_alignment_enum: 0) }
      @cached_value = nil
      @cached_tokens = nil
      super
    end

    def render_text(rt)
      # Parse only if value has changed
      if @cached_value != @value.to_s
        @cached_value = @value.to_s
        parser = RubyParser.new(@cached_value)
        @cached_tokens = parser.parse
      end

      # Find visible range
      f = find_index_at_x(@scroll_x)
      l = find_index_at_x(@scroll_x + @content_w) + 2

      # Calculate character positions and render visible tokens
      char_index = 0

      @cached_tokens.each do |token|
        token_length = token[:value].length
        token_start = char_index
        token_end = char_index + token_length

        # Check if token is in visible range
        if token_end > f && token_start < l
          # Calculate visible portion of token
          visible_start = [token_start, f].max
          visible_end = [token_end, l].min
          visible_text = token[:value][visible_start - token_start, visible_end - visible_start]

          # Get color from theme
          color = @theme[token[:type]] || @text_color

          # Calculate x position for this token
          token_x_offset = @font_style.string_width(@cached_value[f, visible_start - f].to_s) if visible_start > f

          rt.primitives << @font_style.label(
            x: token_x_offset || 0,
            y: @padding,
            text: visible_text,
            **color
          )
        end

        char_index = token_end
        break if char_index >= l
      end
    end
  end
end
