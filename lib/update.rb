module Input
  # This works by:
  #   1. Overriding the `GTK::Runtime#tick_core method` (example found in lowrez.rb)
  #   2. It fetches 'https://github.com/marcheiligers/dr-input/releases/latest' which will redirect to the latest release.
  #      DRGKT follows redirects, so we get the HTML from the final destination.
  #   3. That HTML contains OpenGraph tags including:
  #        `<meta property="og:url" content="/marcheiligers/dr-input/releases/tag/v0.0.25" />`
  #      which contains the latest version number.
  #   4. That then allows us to fetch that version from the releases using $gtk.download_stb_rb_raw
  #   5. Finally it aliases the original `tick_core` method back, and cleans up the methods and instance variables created.
  # State is maintained through the existence of method aliases and instance variables, which are removed on completion.
  # Error handling ensures everything is cleaned up if there is a failure.

  def self.download_update!
    return puts 'Already busy updating' if GTK::Runtime.instance_variable_defined?(:@__input_file_path)

    GTK::Runtime.alias_method(:__input_orig_tick_core, :tick_core)
    GTK::Runtime.instance_variable_set(:@__input_file_path, Input::DEVELOPMENT ? 'input.rb' : 'file.rb')

    GTK::Runtime.define_method(:tick_core) do
      __input_orig_tick_core

      if !instance_variable_defined?(:@__input_version_response)
        @__input_version_response = $gtk.http_get 'https://github.com/marcheiligers/dr-input/releases/latest'
      elsif @__input_version_response[:complete] && !instance_variable_defined?(:@__input_download_response)
        raise "Received status code #{@__input_version_response[:http_response_code]}" unless @__input_version_response[:http_response_code] == 200

        data = @__input_version_response[:response_data]
        search = '<meta property="og:url" content="/marcheiligers/dr-input/releases/tag/v'
        start_char = data.index(search) + search.length
        end_char = data.index('"', start_char)
        @__input_version = data.slice(start_char...end_char)
        puts "Found version #{@__input_version}."
        raise "Remote version is the same as local #{@__input_version}" if @__input_version == Input::VERSION

        url = "https://github.com/marcheiligers/dr-input/releases/download/v#{@__input_version}/input.rb"
        @__input_download_response = $gtk.http_get url
        puts "download: #{@__input_download_response.inspect}"
      elsif instance_variable_defined?(:@__input_download_response) && @__input_download_response[:complete]
        raise "Received status code #{@__input_download_response[:http_response_code]}" unless @__input_download_response[:http_response_code] == 200

        path = self.class.instance_variable_get(:@__input_file_path)
        data = @__input_download_response[:response_data]
        $gtk.write_file path, data

        puts "Updated to version #{@__input_version} at #{path}"
        __input_cleanup_update
      end
    rescue StandardError => e
      puts "Failed to download update: #{e.message}"
      __input_cleanup_update
    end

    GTK::Runtime.define_method(:__input_cleanup_update) do
      self.class.alias_method :tick_core, :__input_orig_tick_core
      self.class.remove_method :__input_orig_tick_core
      self.class.remove_method :__input_cleanup_update
      remove_instance_variable :@__input_version_response if instance_variable_defined? :@__input_version_response
      remove_instance_variable :@__input_version if instance_variable_defined? :@__input_version
      remove_instance_variable :@__input_download_response if instance_variable_defined? :@__input_download_response
      self.class.remove_instance_variable :@__input_file_path if self.class.instance_variable_defined? :@__input_file_path
    end
  end
end
