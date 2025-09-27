def build_text_input(value, selection_start = 0, selection_end = selection_start, **attr)
  Input::Text.new(value: value, selection_start: selection_start, selection_end: selection_end, **attr)
end

def make_word_break_error(input, actual, expected)
  <<-EOS
    Starting '#{input.value.to_s.dup.insert(input.selection_end, '|')}'
    Actual   '#{input.value.to_s.dup.insert(actual, '|')}'
    Expected '#{input.value.to_s.dup.insert(expected, '|')}'
  EOS
end

def assert_finds_word_break_left(assert, starting, expected)
  selection_end = starting.index('|')
  expected = expected.index('|')
  input = build_text_input(starting.delete('|'), selection_end)
  actual = input.find_word_break_left
  assert.equal! actual, expected, make_word_break_error(input, actual, expected)
end

def assert_finds_word_break_right(assert, starting, expected)
  selection_end = starting.index('|')
  expected = expected.index('|')
  input = build_text_input(starting.delete('|'), selection_end)
  actual = input.find_word_break_right
  assert.equal! actual, expected, make_word_break_error(input, actual, expected)
end

def make_current_word_error(input, actual, expected)
  <<-EOS
    Starting '#{input.value.to_s.dup.insert(input.selection_end, '|')}'
    Actual   #{actual.nil? ? 'nil' : "'#{actual}'"}
    Expected #{expected.nil? ? 'nil' : "'#{expected}'"}
  EOS
end

def assert_current_word(assert, starting, expected)
  selection_end = starting.index('|')
  input = build_text_input(starting.delete('|'), selection_end)
  actual = input.current_word
  assert.equal! actual, expected, make_current_word_error(input, actual, expected)
end

def build_multiline_input(width_in_letters)
  # This works because the default DR font is monospaced
  width, _ = $gtk.calcstringbox('1' * width_in_letters, 0)
  Input::Multiline.new(w: width)
end

def word_wrap_result(string, width_in_letters = 10)
  multiline = build_multiline_input(10)
  multiline.insert string
  multiline.lines.map(&:text)
end

def mouse_is_at(x, y)
  $args.inputs.mouse.x = x
  $args.inputs.mouse.y = y
end

def mouse_is_inside(rect, x: nil)
  mouse_is_at(
    x || rect.x + rect.w.half,
    rect.y + rect.h.half
  )
end

def mouse_down
  $args.inputs.mouse.button_left = true
  $args.inputs.mouse.click = GTK::MousePoint.new($args.inputs.mouse.x, $args.inputs.mouse.y)
  $args.inputs.mouse.up = false
end

def mouse_up
  $args.inputs.mouse.button_left = false
  $args.inputs.mouse.click = nil
  $args.inputs.mouse.up = true
end