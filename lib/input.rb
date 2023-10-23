# Initially based loosely on code from Zif
require_relative 'value.rb'
require_relative 'line_collection.rb'
require_relative 'base.rb'
require_relative 'text.rb'
require_relative 'multiline.rb'

$clipboard = ''

# TODO: Switch clipboard to system clipboard when setclipboard is available
# TODO: Drag selected text
# TODO: Max length
# TODO: Home key and End key
# TODO: Render Squiggly lines
# TODO: Current input word getter
# TODO: “ghosting text” feature
# TODO: Find/Replace (all)
# TODO: Prompt text (ghosted text when field is empty)
# TODO: Replace unavailable chars with [?]
