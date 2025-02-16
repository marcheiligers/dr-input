# v0.0.23 - 17 February 2025

* Exposed `@text_keys` as an instance variable instead of a local.
* Wrote up notes on custom keyboard handling with a filtering example.
* Documented `#delete_forward` and `#delete_back` methods.
* Deprecated `on_clicked` and added `on_click` in it's place.
* Documented `focused` argument and `#focused?` aliases for `focussed` and `#focussed?`

# v0.0.22 - 9 February 2025

* Fixed a bug when using `max_length` where `selection_end` (and `selection_start`) where incorrectly set (thanks to @TheCire for reporting in Discord).
* Fixed a cursor placement and selection background issues in the `Text` component.

# v0.0.21 - 4 January 2025

* Updated clipboard to use getclipboard and setclipboard so the system clipboard is used
* Updated menu to handle scrolling with keyboard if there are too many items, including menu sizing
* First pass at menu positioning which tries to maximize the height to show as many items as possible
* Added `:focused` alias for `:focussed` and `focused?` for `focussed?`
* Added autocomplete filtering as you type
* Added `#shift_lock` attribute which helps with autocomplete on the prompt

# v0.0.20 - 11 August 2024

* The cursor now returns to (nearly) full alpha while you're typing (or the value is changed in some other way)
* Exposed `value_changed` accessor which is true if the value changed in the last tick

# v0.0.19 - 10 August 2024

* Slight optimizations in reflow, including not reflowing the text if you assign the same `w`, `size_enum` or `size_px`.

# v0.0.18 - 28 July 2024

* Added `#size_px=`, `#size_enum=` and updated `#w=` to allow resizing or changing the font size of the `Multiline`
  * Note: this causes the content to be "reflowed" (find word breaks) which may impact performance for large texts
  * Note: odd pixel sizes for fonts appear to measure incorrectly, so stick to even font sizes
  * Updated "book" sample with a resizer and font size controls to demonstrate the above
* This release contains experimental Menu support as part of the DragonRuby console prompt replacement

# v0.0.17 - 24 May 2024

* Moved `FontStyle` module inside `Input` module to avoid global namespace pollution

# v0.0.16 - 19 May 2024

* Added experimental support for replacing the DragonRuby console prompt
  * Use `Input.replace_console!` to enable (See `book_sample.rb`)

# v0.0.15 - 18 May 2024

* Fixed a bug in `current_word` where 'wor|d pair' would result in 'word pair' being returned
* Fixed performance for `current_word` in very long words in large documents

# v0.0.14 - 17 May 2024

* Added support for `size_px` to specify font-sizes

# v0.0.13 - 16 May 2024

* Fixed a bug where the input would break if `size_enum` is specified as a number
* Refactored string size calculations by encapsulating them into a `FontStyle` object

# v0.0.12 - 12 May 2024

* Fixes wrapping of words longer than the width of the multi-line input
* Fixes tests, such as they are

# v0.0.11 - 28 April 2024

* Added `{dir}_arrow` to fix cursor keys not working in recent 5.2X versions

# v0.0.10 - 11 February 2024

* Fixed release date for 0.0.9 below (off by a month)
* Removed padding from selection highlight to remove overlap in `Multiline`
* Added `fill_from_bottom` option to `Multiline` for things like logs or game terminals
* Added color parsing code allowing `text_color`, `background_color`, `blurred_background_color`, `prompt_color`, `selection_color`, and `blurred_selection_color` parameters to be passed as an `Array`, `Hash`, `Integer` or separate `Integer` values with `_r`, `_g`, `_b` and `_a` suffixes
* Added `cursor_color` and `cursor_width`
* Added `delete_forward` and started treating delete and backspace correctly
* Added Basic sample and updated README
* Implemented `Home` and `End` keys
* Added `insert_at(str, start_at, end_at)`
* Added `append(str)`
* Added `scroll_to(y)`
* Breaking: renamed `content_y` to `scroll_y` and `content_x` to `scroll_x`
* Made `scroll_x` and `scroll_y` accessors, and ensured that the `@ensure_cursor_visible` internal variable is correctly reset
* Updated `Scroller` in samples to react to clicks outside the thumbtrack with page up/down, and dragging the thumbtrack
* Updated Log sample

# v0.0.9 - 3 February 2024

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

// Sunday 08/11/24 at 09:46AM - 48 files in 0.15 secs

## BUG (1)
1. lib/console.rb:145           Tab autocompletion failed. Let us know about this.\n#{e}"

## TODO (30)
1. lib/line_collection.rb:55    Test `index_at` with multiple different fonts
2. lib/line_collection.rb:169   prolly need to replace \r\n with \n up front
3. lib/line_collection.rb:173   consider how to render TAB, maybe convert TAB into 4 spaces?
4. lib/line_collection.rb:179   consider smarter handling. "something!)something" would be considered a word right now, theres an extra step needed
5. lib/line_collection.rb:197   consider how to render TAB, maybe convert TAB into 4 spaces?
6. lib/line_collection.rb:236   make this a binary search
7. lib/text.rb:35               undo/redo
8. lib/text.rb:96               Word selection (double click), All selection (triple click)
9. lib/text.rb:150              handle padding correctly
10. lib/text.rb:167             implement sprite background
11. lib/input.rb:14             Switch clipboard to system clipboard when setclipboard is available
12. lib/input.rb:15             Drag selected text
13. lib/input.rb:16             Render Squiggly lines
14. lib/input.rb:17             “ghosting text” feature
15. lib/input.rb:18             Find/Replace (all)
16. lib/input.rb:19             Replace unavailable chars with [?]
17. lib/menu.rb:99              home, pgup, end, pgdn
18. lib/menu.rb:100             optional find by text
19. lib/menu.rb:194             Fix menu value=
20. lib/menu.rb:248             Implement line spacing
21. lib/menu.rb:257             implement sprite background
22. lib/menu.rb:260             implement scrolling
23. lib/multiline.rb:75         undo/redo
24. lib/multiline.rb:129        Retain a original_cursor_x when moving up/down to try stay generally in the same x range
25. lib/multiline.rb:135        beginning of previous paragraph with alt
26. lib/multiline.rb:144        end of next paragraph with alt
27. lib/multiline.rb:281        Word selection (double click), All selection (triple click)
28. lib/multiline.rb:343        Implement line spacing
29. lib/multiline.rb:353        implement sprite background
30. lib/multiline.rb:382        Line visibility
