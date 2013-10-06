require "micromidi"
require "topaz"

@@bpm = 132
@input = UniMIDI::Input.first.open

class Song

  def initialize score
    @counter = 0
    @score = []
    score.each do |row|
      row.first.times do
        @score << row.last
      end
    end
  end

  def step
    if @score[@counter/8]
      @score[@counter/8].each do |seq|
        seq.step
      end
    end
    @counter += 1

  end

end

class Loop

  def initialize device, channel, notes, pattern
    @pattern_idx = 0
    @notes_idx = 0
    @midi = MIDI.using(UniMIDI::Output.use(device))
    @midi.channel channel
    @t4 = 60.0/@@bpm
    @t16 = @t4/4
    @pattern = pattern.collect{|s| s.to_i > 0 ? true : false }
    @notes = [notes].flatten
  end

  def step
    @pattern_idx = 0 if @pattern_idx >= @pattern.size
    @notes_idx = 0 if @notes_idx >= @notes.size
    @midi.play @notes[@notes_idx], @t16 if @pattern[@pattern_idx]
    @pattern_idx+=1
    @notes_idx+=1
  end

end

bass = Loop.new 0, 15, ["C2","G3","D3","C4"], [1,1,0,1,1,0]
kick = Loop.new 1, 9, "C2", [1,0,0,0]

score = [
  [8, [kick]],
  [16, [kick,bass]],
  [8, [bass]]
]

song = Song.new score
@tempo = Topaz::Tempo.new(@@bpm, :interval => 16) do
  song.step
end
@tempo.start#(:background => true)


#TODO: note offs
#

=begin
input = UniMIDI::Input.first
input.open do |input|

  puts "send some MIDI to your input now..."

  loop do
    m = input.gets
    puts(m)
  end

end
=end
