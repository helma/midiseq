require "micromidi"
require "topaz"

class Timer < Topaz::Tempo
  attr_reader :counter, :clockin
  def initialize
    @clockin = UniMIDI::Input.use 0
    @counter = 0
    @dcounter = 0
    @length = 8*16
    #TODO wait for start/stop
    super @clockin, :interval => 32 do
      @dcounter = (@dcounter + 1) % (2*@length)
      @counter = @dcounter/2
    end
  end
  def rec_counter # quantize recordings
    (@dcounter+1)/2
  end
end

class Recorder 

  attr_reader @sequence
  def initialize timer
    @timer = timer
    @sequence = Array.new @length
    @midiin =  UniMIDI::Input.use 1
    recorder = MIDIEye::Listener.new(@midiin)
    recorder.listen_for(:class => [MIDIMessage::NoteOn, MIDIMessage::NoteOff]) do |event|
      if event.class == MIDIMessage::NoteOn
        @opennotes[event[:message].note] = [event[:message], @timer.rec_counter]
      elsif event.class == MIDIMessage::NoteOff
        onmessage = @opennotes[event[:message].note].first
        start = @opennotes[event[:message].note].last
        dur = @timer.rec_counter - start
        @sequence[start] = [onmessage.note, onmessage.velocity, dur]
      end
    end
    recorder.run(:background => true)
  end

end

class Player  < Topaz::Tempo

  def initialize recorder
    @recorder = recorder
    @timer = recorder.timer
    @midiout =  UniMIDI::Output.use 1
    @midiout.channel 15
    @sequence = recorder.sequence
    super @timer.clockin, :interval => 16 do
      pid = fork do
        step = @sequence[@timer.counter]
        @midiout.velocity step[1]
        @midiout.play step[0], step[2]*60/@timer.tempo/4
      end
      Process.detach pid
    end
  end

  def record
    @sequence = recorder.sequence
  end
end

player = Player.new(Recorder.new(Timer.new))
sleep 2
player.start
sleep 4
player.stop

