# v0.0.9 - 3 January 2024

* Added `readonly` option
* Fixed a bug where `Multiline` would break if the `value` is `nil` at initialization
* Fixed a bug where `Multiline#lines` was returning nil
* Added Log sample app
* Fixed a bug where when content is shorter than height, mouse is off

# v0.0.8 - 29 October 2023

* Made `handle_mouse` and `on_clicked` smarter to handle right clicks
* Fixed "EXCEPTION: wrong number of arguments (2 for 0)" for `NOOP`
* Added `max_length`
* Added `#current_word`
* Added `prompt` and `prompt_*` (`r`, `g`, `b`, `a`)

# v0.0.7 - 21 October 2023

* Multiline Performance
  * Draw only the lines in the view
  * Speed up word break finding with Hashes
  * Update edits to use data model instead or reparsing entire value
* Text Performance
  * Draw text in the view
  * Change `find_index_at_x` to use Binary search
* Speed up key repeat slight (4 ticks instead of 5 default)

# v0.0.6 - 10 September 2023

* Added `rect` method
* Fixed: Cursor renders outside of the bounds of the control
* Adjusted index finding for up/down cursor movement in `Multiline`
* Added scrolling for `Multiline` and exposed `#content_h` getter to help with building scroll bars
* Added `#find`, `#find_next` (`[meta|ctrl]+[g]`), `#find_prev` (`[meta|ctrl]+[shift]+[g]`) methods
* Added `#move_page_up`, `#move_page_down`, `#select_page_up`, `#select_page_down` methods and keyboard short cuts


# v0.0.5 - 2 September 2023

* Refactored to use `module Input` and classes `Text` and `Multiline`
* Fixed: move to start and end of line for Multiline
* Updated multiline selection to stop at text end
* Up and down for multiline no longer move to start and end on the first and last lines respectively anymore
* Fixed: up and down not working from the start of the line in multiline
* Refactored to use methods in response to keyboard, and documented methods
* Renamed `#focus!` to `focus`, and `blur!` to `blur`
* Added blurred colors
* Documented accessors

# v0.0.4 - 27 August 2023

* Added a background color property.
  * Having a background improves the rendering quality.
* Added some usage notes to the README.md
* Fixed: Inserting multiple characters (paste, or multiple characters) in a single tick
* Implement key repeat for cursor movement
* Fixed: At some point walking single character words was fixed
* Added focus state, `#focussed?`, `#focus`, `#blur`
* Added `on_clicked` and `on_unhandled_key` callbacks
* Added mouse selection for word wrapped control
* Added up and down (without `[alt]`) for word wrapped control
* Improved mouse selection (finding cursor index by x position) for word wrapped input
* Introduced `LineCollection` data structure for word wrap to centralize a lot of the line handling, measuring and so on
* Broke out classes for different input types
* Fixed (some) cursor start of line/end of line weirdnesses

# v0.0.3 - 20 August 2023

* Word-wrap option and smart word breaks algorithm, with some tests
* Cursor for wrapping text
* Text selection for wrapping text, including multi-line selection
* Fixed: Something is wrong with inserting at the end
* Fixed: Rendering issue when deleting from non-wrapping field

# v0.0.2 - 14 August 2023

* Add cut, copy, paste
* Added (initial) Rubocop config
* Moved all known issues into TODO and BUG comments

# v0.0.1 - 13 August 2023

* First release
* Text entry (I mean, this is the very least it could do)
* Automatic height calc based on font and size (optional)
* Flashing cursor
* Cursor control
  * [Left], [Right]
  * [Alt]+[Left], [Alt]+[Right] to word boundaries
  * [Meta]+[Left], [Ctrl]+[Left], [Ctrl]+[Right], [Meta]+[Right] to beginning, end
* Selection with [Shift] and cursor control
* [Meta]+[A], [Ctrl]+[A] select all
* Mouse cursor positioning and selection
* Mouse selection with [Shift] and current cursor location
* Scrolling when the value is longer than the input

# Known Issues and TODO

// Saturday 02/03/24 at 02:21PM - 40 files in 0.11 secs

## BUG (2)
1. lib/base.rb:23               Modifier keys are broken on the web ()
2. lib/multiline.rb:201         If the first line has only one char, down moves right from the first column

## TODO (28)
1. lib/base.rb:148              cursor size
2. lib/base.rb:149              cursor color
3. lib/base.rb:257              Improve walking words
4. lib/line_collection.rb:56    Test `index_at` with multiple different fonts
5. lib/line_collection.rb:173   prolly need to replace \r\n with \n up front
6. lib/line_collection.rb:177   consider how to render TAB, maybe convert TAB into 4 spaces?
7. lib/line_collection.rb:183   consider smarter handling. "something!)something" would be considered a word right now, theres an extra step needed
8. lib/line_collection.rb:201   consider how to render TAB, maybe convert TAB into 4 spaces?
9. lib/text.rb:34               undo/redo
10. lib/text.rb:61              Treat delete and backspace differently
11. lib/text.rb:88              Word selection (double click), All selection (triple click)
12. lib/text.rb:142             handle padding correctly
13. lib/text.rb:159             implement sprite background
14. lib/input.rb:10             Switch clipboard to system clipboard when setclipboard is available
15. lib/input.rb:11             Drag selected text
16. lib/input.rb:12             Home key and End key
17. lib/input.rb:13             Render Squiggly lines
18. lib/input.rb:14             “ghosting text” feature
19. lib/input.rb:15             Find/Replace (all)
20. lib/input.rb:16             Replace unavailable chars with [?]
21. lib/multiline.rb:46         undo/redo
22. lib/multiline.rb:91         Retain a original_cursor_x when moving up/down to try stay generally in the same x range
23. lib/multiline.rb:97         beginning of previous paragraph with alt
24. lib/multiline.rb:106        end of next paragraph with alt
25. lib/multiline.rb:238        Word selection (double click), All selection (triple click)
26. lib/multiline.rb:294        Implement line spacing
27. lib/multiline.rb:304        implement sprite background
28. lib/multiline.rb:336        Ensure cursor_x doesn't go past the line width
