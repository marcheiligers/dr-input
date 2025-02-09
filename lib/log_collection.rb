module Input
  class Log
    attr_reader :count

    def initialize(text, line_parser, color = 0xffffff)
      @line_parser = line_parser
      @line_collection = @line_parser.perform_word_wrap(text, @w)

      @count = 1
    end

    def to_s
      @line_collection.to_s
    end

    def ==(log)
      log.is_a?(String) ? to_s == log : to_s == log.to_s
    end

    def another!
      count += 1
    end
  end

  class LogCollection
    attr_reader :logs

    include Enumerable

    def initialize(logs = [])
      @logs = logs
    end

    def each
      @logs.each { |log| yield(log) }
    end

    def length
      @logs.length
    end

    def [](num)
      @logs[num]
    end

    def first
      @logs.first
    end

    def last
      @logs.last
    end

    def <<(log)
      if last == log
        last.another!
      else
        @logs.append(log)
      end
      self
    end

    def empty?
      @logs.empty?
    end

    def replace(old_logs, new_logs)
      @logs = (@logs[0, old_logs.first.number] || []) + new_logs.logs + (@logs[old_logs.last.number + 1, @logs.length] || [])

      i = new_logs.last.number
      l = @logs.length
      s = new_logs.last.end
      while (i += 1) < l
        log = @logs[i]
        log.number = i
        log.start = s
        s = log.end
      end
    end

    def modified(from_index, to_index)
      to_index, from_index = from_index, to_index if from_index > to_index
      log = log_at(from_index)
      modified_logs = []
      i = log.number
      loop do
        modified_logs << log
        break unless log.end < to_index || log.wrapped?

        log = @logs[i += 1]
      end

      logCollection.new(modified_logs)
    end

    def text
      @logs.map(&:text).join
    end

    def log_at(index)
      @logs.detect { |log| index <= log.end } || @logs.last
    end

    def inspect
      @logs.map(&:inspect)
    end
  end
end
