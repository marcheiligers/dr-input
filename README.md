# dr-input

A simple input control for DragonRuby.

The Multiline input is fast enough to edit _Alice's Adventures in Wonderland_ (~170k character), but _War and Peace_ (~3.3M characters) is over the limits. This limit doesn't appear to be related to the code, as even loading the _War and Peace_ text file takes multiple seconds (M1 Pro Max). I have not explored where the limit is beyond a simple experiment with these two files from [Project Gutenberg](https://www.gutenberg.org), but if you need to edit a reasonable sized novel, perhaps a chapter-based approach is better anyway.

## Usage

Grab the latest single file release `input.rb` from the [Releases](https://github.com/marcheiligers/dr-input/releases) page and save it in your DragonRuby game folder (I'm assuming in a `lib` directory in the sample below).


```ruby
require 'lib/input.rb'

def tick(args)
  # Create an input
  args.state.input ||= Input::Text.new(x: 100, y: 600, w: 300, focussed: true)

  # Allow the input to process inputs and render text (render_target)
  args.state.input.tick

  # Get the value
  args.state.input_value = args.state.input.value

  # Output the input
  args.outputs.primitives << args.state.input

  # Output the value
  args.outputs.debug << { x: 100, y: 100, text: args.state.input_value }.label!
end
```

See `app/main.rb` for a more complex example.


### Constructor Arguments

#### Colors

Color arguments can be passed as `Hash`es or `Array`s suffixed with `_color`, or individual `Integer` values suffixed with `_r`, `_g`, `_b`, `_a`. In all cases, if a color element is missing, the corresponding default value will be used.

For example, for the `prompt` you can pass:
* A `prompt_color` as a `Hash`, like `{ r: 100, g: 100, b: 100, a: 255 }`
* A `prompt_color` as an `Array`, like `[100, 100, 100, 255]`
* A `prompt_color` as an `Integer`, like `0xFF33BB`
* Individual `prompt_r`, `prompt_g`, `prompt_b` and `prompt_a` `Integer` values

The argument list below will list `prompt_color` but not the individual `prompt_*` values.

#### Arguments

* `x` - x location, default 0
* `y` - y location, default 0
* `w` - width, default 256
* `h` - height, default is the height of the font (as measured by `calcstringbox`) + 2 * the `padding`
* `value` - initial input value (string), default ''
* `padding` - padding, default 2
* `font` - font path (eg. `'fonts/myfont.ttf'`), default ''
* `size_enum` - size enumeration (integer), or named size such as `:small`, `:normal`, `:large`, default: `:normal` (`0`)
* `text_color` - text color, default `{ r: 0, g: 0, b: 0, a: 255 }`
* `r` - text color, red component, default 0, used if `text_color` is `nil`
* `g` - text color, green component, default 0, used if `text_color` is `nil`
* `b` - text color, blue component, default 0, used if `text_color` is `nil`
* `a` - text color, alpha component, default 255, used if `text_color` is `nil`
* `prompt` - prompt text - ghosted text when the control is empty, default ''
* `prompt_r` - prompt color, default `{ r: 128, g: 128, b: 128, a: 255 }`
* `cursor_color` - cursor color, default `{ r: 0, g: 0, b: 0, a: 255 }`
* `cursor_width` - cursor width, default 2
* `background_color` - background color, default nil (non-nil default components, `{ r: 0, g: 0, b: 0, a: 255 }`)
* `blurred_background_color` - background color, default `background_color` (non-nil default components, `{ r: 0, g: 0, b: 0, a: 255 }`)
* `word_chars` - characters considered to be parts of a word, default `('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-']`
* `punctuation_chars` - charcters considered to be punctuation, default `%w[! % , . ; : ' " \` ) \] } * &]`
* `selection_start` - start of the selection (if any) in characters (Integer), default the length of the initial value
* `selection_end` - end of the selection (if any) and the location of the cursor in characters (Integer), default `selection_start`
* `selection_color` - selection color, default `{ r: 102, g: 178, b: 255, a: 128 }`
* `blurred_selection_color` - blurred selection color, default `{ r: 112, g: 128, b: 144, a: 128 }`
* `key_repeat_delay` - delay before function key combinations (cursor, cut/copy/paste and so on) begin to repeat in ticks (Integer), default 20
* `key_repeat_debounce` - number of ticks (Integer) between function key repeat, default 4
* `word_wrap` - if the control should wrap (Boolean), default false
* `readonly` - initial input read only state (Boolean), default false
* `focussed` - initial input focus (Boolean), default false
* `on_clicked` - on click callback, receives 2 parameters, the click and the `Input` control instance, default NOOP
* `on_unhandled_key` - on unhandle key pressed callback, receives 2 parameters, the key and the `Input` control instance, default NOOP. This callback receives keys like `[tab]` and `[enter]`
* `max_length` - maximum allowed length (Integer), default `false` which disables length checks
* `fill_from_bottom` - fill the text from the bottom, like for a log or game terminal, default `false`

### Attribute accessors

* `value` - The current value
* `selection_start` - The start of the current selection
* `selection_end` - The end of the current selection. This is the cursor location.
* `lines` - The value broken into individual lines (readonly, `Multiline` only)
* `content_w` - The width of the full content (`value`) as rendered (readonly, `Text` only)
* `content_h` - The height of the full content (`value`) as rendered (readonly, `Multiline` only)
* `rect` - Returns the control's containing rect as a hash (readonly)
* `readonly` - Returns or sets the control's read only state
* `scroll_x` - The x position of the full scrollable area as rendered
* `scroll_y` - The y position of the full scrollable area as rendered. NOTE: `scroll_y = 0` is the bottom
* `scroll_w` - The width of the full scrollable area as rendered (readonly)
* `scroll_h` - The height of the full scrollable area as rendered (readonly)

### Instance Methods

* `#insert(text)` - Inserts text at the cursor location, or replaces if there's a selection
* `#insert_at(text, start, end = start)` - Inserts text at the start location, or replaces if end != start, without changing the selection
* `#replace(text)` - Alias for `#insert(text)`
* `#replace_at(text, start, end = start)` - Alias for `#insert_at(text, start, end = start)`
* `#append(text)` - Appends text the end of the value, without changing the selection
* `#current_selection` - Returns the currently selected text
* `#current_line` - Returns the currently selected line object
* `#current_word` - Returns the word currently under the cursor
* `#find(text)` - Selects the searched for text if found
* `#find_next` - Selects the next instance of the currently selected text
* `#find_prev` - Selects the previous instance of the currently selected text
* `#cut` - Cut selection to `$clipboard`
* `#copy` - Copy selection to `$clipboard`
* `#paste` - Paste value in `$clipboard`
* `#move_to_start` - Move to the start of the current line
* `#move_word_left` - Move the cursor a word to the left
* `#move_char_left` - Move the cursor a character to the left
* `#move_word_right` - Move the cursor a word to the right
* `#move_char_right` - Move the cursor a character to the right
* `#move_line_up` - Move the cursor one line up (`Multiline` only)
* `#move_line_down` - Move the cursor one line up (`Multiline` only)
* `#move_page_up` - Move the cursor one page up (`Multiline` only)
* `#move_page_down` - Move the cursor one page up (`Multiline` only)
* `#select_all` - Select all
* `#select_to_start` - Select to the start of the text value
* `#select_to_line_start` - Select to the start of the current line (`Multiline` only)
* `#select_word_left` - Select a word to the left
* `#select_char_left` - Select a character to the left
* `#select_to_end` - Select to the end of the text value
* `#select_to_line_end` - Select to the end of the current line (`Multiline` only)
* `#select_word_right` - Select a word to the right
* `#select_char_right` - Select a character to the right
* `#select_line_up` - Select one line up (`Multiline` only)
* `#select_line_down` - Select one line down (`Multiline` only)
* `#select_page_up` - Select one page up (`Multiline` only)
* `#select_page_down` - Select one page down (`Multiline` only)
* `#focus` - Focusses the instance. Note the instance will only receive the focus after it's rendered. This prevents multiple instances from handling the keyboard and mouse events in the same tick.
* `#blur` - Removes the focus from the instance. This happens immediately and the instance will not process keyboard and some mouse events after being blurred.
* `#focussed?` - Returns true if the input is focussed, false otherwise

## Notes

* Adding a `background_color` significantly improves the rendering of the text.

## Thanks

* @danhealy for Zif. The Zif Input was the starting point for this. Though you wouldn't be able to tell now, it was a really solid place to start.
* @leviondiscord (on Discord, aka @leviongithub) for suggesting `#delete_prefix` when I would have done something much dumber. And also providing other interesting methods I'm likely to use at some point.
* @DarkGriffin (on Discord) for requesting this control in the first place, and not being shy about the _crazy_ desired feature list (of which, I feel like, I've only touched the surface).
* @aquillo (on Discord) for asking me (and others) to review his code, where I learnt that the value returned by `keyboard.key` is the `tick_count` the key was pressed which made implementing key repeat much simpler than the silly thing I would've done.
* @cookie (on Discord) for reigniting my interest in building this control by asking about how to use it, finding a new, novel use for it, and pushing me to improve the sample(s).
