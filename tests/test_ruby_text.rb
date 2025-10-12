require 'tests/test_helpers.rb'

def test_ruby_text_initialization(args, assert)
  input = Input::RubyText.new(value: 'def foo; end')
  assert.true! input.is_a?(Input::Text), 'RubyText should be a subclass of Text'
  assert.equal! input.value.to_s, 'def foo; end'
end

def test_ruby_text_with_custom_theme(args, assert)
  custom_theme = {
    keyword: { r: 255, g: 0, b: 0 }
  }
  input = Input::RubyText.new(value: 'def foo; end', theme: custom_theme)
  assert.equal! input.instance_variable_get(:@theme)[:keyword], { r: 255, g: 0, b: 0, vertical_alignment_enum: 0 }
end

def test_ruby_text_with_default_theme(args, assert)
  input = Input::RubyText.new(value: 'def foo; end')
  theme = input.instance_variable_get(:@theme)
  assert.equal! theme[:keyword], { r: 197, g: 134, b: 192, vertical_alignment_enum: 0 }
  assert.equal! theme[:string], { r: 152, g: 195, b: 121, vertical_alignment_enum: 0 }
end

def test_ruby_text_parses_and_exposes_tokens(args, assert)
  input = Input::RubyText.new(value: 'def foo; end', x: 0, y: 0, w: 200, h: 30)

  # First render - should parse
  input.tick
  tokens = input.tokens
  assert.true! tokens.is_a?(Array), 'Should have tokens'
  assert.true! tokens.length > 0, 'Should have parsed tokens'

  # Second render with same value - should use cache (value_changed is false)
  input.tick
  tokens2 = input.tokens
  assert.equal! tokens.object_id, tokens2.object_id, 'Should reuse cached tokens when value unchanged'
end
