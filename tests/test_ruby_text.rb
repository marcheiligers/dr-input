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

def test_ruby_text_caches_parse_results(args, assert)
  input = Input::RubyText.new(value: 'def foo; end', x: 0, y: 0, w: 200, h: 30)

  # First render - should parse
  input.prepare_render_target
  cached_tokens = input.instance_variable_get(:@cached_tokens)
  assert.true! cached_tokens.is_a?(Array), 'Should cache tokens'
  assert.true! cached_tokens.length > 0, 'Should have parsed tokens'

  # Second render with same value - should use cache
  input.prepare_render_target
  cached_tokens2 = input.instance_variable_get(:@cached_tokens)
  assert.equal! cached_tokens.object_id, cached_tokens2.object_id, 'Should reuse cached tokens'
end

def test_ruby_text_reparses_on_value_change(args, assert)
  input = Input::RubyText.new(value: 'def foo; end', x: 0, y: 0, w: 200, h: 30)

  # First render
  input.prepare_render_target
  cached_tokens = input.instance_variable_get(:@cached_tokens)

  # Change value
  input.insert('bar')

  # Second render - should reparse
  input.prepare_render_target
  cached_tokens2 = input.instance_variable_get(:@cached_tokens)
  assert.true! cached_tokens.object_id != cached_tokens2.object_id, 'Should reparse on value change'
end
