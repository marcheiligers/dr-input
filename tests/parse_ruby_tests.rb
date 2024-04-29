require 'lib/input.rb'

def build_expected(*expected_pairs)
  expected = []
  pos = 0
  expected_pairs.each_slice(2) do |str, type|
    expected << Input::Token.new(str, type, pos)
    pos += str.length
  end
  expected
end

# def test_parse_int(_args, assert)
#   result = Input::RubyParser.new.parse('123')
#   expected = [Input::Token.new('123', :int, 0)]
#   assert.equal! result, expected
# end

# def test_parse_int_with_underscore(_args, assert)
#   result = Input::RubyParser.new.parse('1_234')
#   expected = [Input::Token.new('1_234', :int, 0)]
#   assert.equal! result, expected
# end

# def test_parse_int_with_method_call(_args, assert)
#   result = Input::RubyParser.new.parse('123.to_s')
#   expected = build_expected('123', :int, '.', :dot, 'to_s', :method_call)
#   assert.equal! result, expected
# end

# def test_parse_float(_args, assert)
#   result = Input::RubyParser.new.parse('1.23')
#   expected = [Input::Token.new('1', :int, 0), Input::Token.new('.', :dot, 1), Input::Token.new('23', :float, 2)]
#   assert.equal! result, expected
# end

# def test_parse_float_with_underscore(_args, assert)
#   result = Input::RubyParser.new.parse('1_234.56')
#   expected = [Input::Token.new('1_234', :int, 0), Input::Token.new('.', :dot, 5), Input::Token.new('56', :float, 6)]
#   assert.equal! result, expected
# end

# def test_parse_float_with_method_call(_args, assert)
#   result = Input::RubyParser.new.parse('1.23.to_s')
#   expected = [Input::Token.new('1', :int, 0), Input::Token.new('.', :dot, 1), Input::Token.new('23', :float, 2), Input::Token.new('.', :dot, 4), Input::Token.new('to_s', :method_call, 5)]
#   assert.equal! result, expected
# end

# def test_parse_float_with_too_many_dots(_args, assert)
#   result = Input::RubyParser.new.parse('1.23.45')
#   expected = [Input::Token.new('1', :int, 0), Input::Token.new('.', :dot, 1), Input::Token.new('23', :float, 2), Input::Token.new('.', :dot, 4), Input::Token.new('45', :error, 5)]
#   assert.equal! result, expected
# end

# def test_parse_hex(_args, assert)
#   result = Input::RubyParser.new.parse('0xFF9900')
#   expected = [Input::Token.new('0xFF9900', :int, 0)]
#   assert.equal! result, expected
# end

# def test_parse_bad_hex(_args, assert)
#   result = Input::RubyParser.new.parse('0xFF990G')
#   expected = build_expected('0xFF990', :int, 'G', :error)
#   assert.equal! result, expected
# end

# def test_parse_oct(_args, assert)
#   result = Input::RubyParser.new.parse('01234567')
#   expected = [Input::Token.new('01234567', :int, 0)]
#   assert.equal! result, expected
# end

# def test_parse_bad_oct(_args, assert)
#   result = Input::RubyParser.new.parse('01234568')
#   expected = build_expected('0123456', :oct, '8', :error)
#   assert.equal! result, expected
# end

# def test_parse_operator(_args, assert)
#   result = Input::RubyParser.new.parse('*')
#   expected = [Input::Token.new('*', :operator, 0)]
#   assert.equal! result, expected
# end

# def test_parse_2_char_operator(_args, assert)
#   result = Input::RubyParser.new.parse('+=')
#   expected = [Input::Token.new('+=', :operator, 0)]
#   assert.equal! result, expected
# end

# def test_parse_3_char_operator(_args, assert)
#   result = Input::RubyParser.new.parse('+==')
#   expected = build_expected('+=', :operator, '=', :error)
#   assert.equal! result, expected
# end

# def test_parse_numeric_expression(_args, assert)
#   result = Input::RubyParser.new.parse('1_234 + 4_567 == 5801')
#   expected = build_expected(
#     '1_234', :int,
#     ' ', :whitespace,
#     '+', :operator,
#     ' ', :whitespace,
#     '4_567', :int,
#     ' ', :whitespace,
#     '==', :operator,
#     ' ', :whitespace,
#     '5801', :int
#   )
#   assert.equal! result, expected
# end

# def test_parse_method_definition(_args, assert)
#   result = Input::RubyParser.new.parse('def parse(str)')
#   expected = build_expected(
#     'def', :keyword,
#     ' ', :whitespace,
#     'parse', :keyword,
#     '(', :bracket,
#     'str', :keyword,
#     ')', :bracket
#   )
#   assert.equal! result, expected
# end

# def test_parse_comment(_args, assert)
#   result = Input::RubyParser.new.parse('# this is a comment')
#   expected = build_expected('# this is a comment', :comment)
#   assert.equal! result, expected
# end

# def test_parse_instance_var(_args, assert)
#   result = Input::RubyParser.new.parse('@instance_var')
#   expected = build_expected('@instance_var', :instance_var)
#   assert.equal! result, expected
# end

# def test_parse_instance_var(_args, assert)
#   result = Input::RubyParser.new.parse('$gtk')
#   expected = build_expected('$gtk', :global_var)
#   assert.equal! result, expected
# end

# def test_parse_simple_symbol(_args, assert)
#   result = Input::RubyParser.new.parse(':symbol')
#   expected = build_expected(':symbol', :symbol)
#   assert.equal! result, expected
# end

# def test_parse_simple_double_quoted_string(_args, assert)
#   result = Input::RubyParser.new.parse('"str"')
#   expected = build_expected('"str"', :double_quoted_str)
#   assert.equal! result, expected
# end

# def test_parse_double_quoted_string_with_escape_char(_args, assert)
#   result = Input::RubyParser.new.parse('"line1\nline2"')
#   expected = build_expected('"line1', :double_quoted_str, '\n', :escape_char, 'line2"', :double_quoted_str)
#   assert.equal! result, expected
# end

# def test_parse_double_quoted_string_with_escape_char_double_quote(_args, assert)
#   result = Input::RubyParser.new.parse('"line1\"line2"')
#   expected = build_expected('"line1', :double_quoted_str, '\"', :escape_char, 'line2"', :double_quoted_str)
#   assert.equal! result, expected
# end

# def test_parse_double_quoted_string_interpolation(_args, assert)
#   result = Input::RubyParser.new.parse('"foo_#{bar}_baz"')
#   expected = build_expected('"foo_', :double_quoted_str, '#{', :interpolation, 'bar', :keyword, '}', :interpolation, '_baz"', :double_quoted_str)
#   assert.equal! result, expected
# end

def test_parse_double_quoted_string_interpolation_with_hash(_args, assert)
  result = Input::RubyParser.new.parse('"args = #{ { x: 1 } }"')
  expected = build_expected(
    '"args = ', :double_quoted_str,
    '#{', :interpolation,
    ' ', :whitespace,
    '{', :bracket,
    ' ', :whitespace,
    'x:', :symbol,
    ' ', :whitespace,
    '1', :int,
    ' ', :whitespace,
    '}', :bracket,
    ' ', :whitespace,
    '}', :interpolation,
    '"', :double_quoted_str
  )
  assert.equal! result, expected
end
