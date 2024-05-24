# Initially based loosely on code from Zif (https://github.com/danhealy/dragonruby-zif)
require_relative 'util.rb'
require_relative 'value.rb'
require_relative 'line_collection.rb'
require_relative 'font_style.rb'
require_relative 'base.rb'
require_relative 'text.rb'
require_relative 'multiline.rb'
require_relative 'console.rb'

$clipboard = ''

# TODO: Switch clipboard to system clipboard when setclipboard is available
# TODO: Drag selected text
# TODO: Render Squiggly lines
# TODO: “ghosting text” feature
# TODO: Find/Replace (all)
# TODO: Replace unavailable chars with [?]
