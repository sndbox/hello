require 'dotenv'
require 'em-websocket'
require 'pathname'
require 'webrick'

Dotenv.load

raise "No WordNet" unless ENV.has_key?('WORDNET_DIR')

class Candidate
  def initialize()
    @words = []
    collect_words
    @dp = (0...20).map { Array.new(20, 0) }
    (0...20).each {|i| @dp[0][i] = i; @dp[i][0] = i }
    puts "#{@words.length} words"
  end

  def lookup(target)
    dist = target.length / 3 + 1
    results = []
    @words.each {|candidate|
      results << candidate if levdist(target, candidate, dist)
      break if results.length >= 10
    }
    return results
  end

  private

  def levdist(a, b, dist = 1)
    return false if (a.length-b.length).abs > dist
    (1..a.length).each do |i|
      (1..b.length).each do |j|
        if a[i-1] == b[j-1]
          @dp[i][j] = @dp[i-1][j-1]
        else
          @dp[i][j] = [@dp[i-1][j], @dp[i][j-1], @dp[i-1][j-1]].min + 1
        end
      end
    end
    return @dp[a.length][b.length] <= dist
  end

  def collect_words()
    Dir.glob(File.join(ENV['WORDNET_DIR'], 'dict', 'index.*')) do |index_file|
      read_file(index_file)
    end
  end

  def read_file(index_file)
    File.open(index_file).each do |line|
      next if line.start_with? ' '
      word, _ = line.split
      @words << word.gsub('_', ' ')
    end
  end
end

def run(candidate)
  EM.run {
    EM::WebSocket.run(:host => "0.0.0.0", :port => 8084) do |ws|
      ws.onopen { puts "connection open" }
      ws.onclose { puts "connection closed" }
      ws.onmessage { |msg|
        results = candidate.lookup(msg.chop).join(", ")
        ws.send "Results: #{results}"
      }
    end
  }
end

candidate = Candidate.new
run(candidate)
