=begin
require "unimidi"
require "micromidi"
require "topaz"

class Timer < Topaz::Tempo
  attr_reader :counter, :clockin, :length
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
    start :background => true
  end
  def rec_counter # quantize recordings
    (@dcounter+1)/2
  end
end

class Recorder 

  attr_reader :sequence, :timer
  def initialize timer
    @timer = timer
    @sequence = Array.new @timer.length
    @midiin =  UniMIDI::Input.use 1
    #Topaz::Tempo.new @timer.clockin, :interval => 16 do
      #@sequence[@timer.counter] = nil
    #end
    recorder = MIDIEye::Listener.new(@midiin)
    recorder.listen_for(:class => [MIDIMessage::NoteOn, MIDIMessage::NoteOff]) do |event|
        puts event.inspect
#      if event.class == MIDIMessage::NoteOn
#        @opennotes[event[:message].note] = [event[:message], @timer.rec_counter]
#      elsif event.class == MIDIMessage::NoteOff
#        onmessage = @opennotes[event[:message].note].first
#        start = @opennotes[event[:message].note].last
#        dur = @timer.rec_counter - start
#        @sequence[start] = [onmessage.note, onmessage.velocity, dur]
#      end
    end
    recorder.run(:background => true)
  end

end

class Player  < Topaz::Tempo

  def initialize recorder
    @recorder = recorder
    @timer = recorder.timer
    @midiout =  UniMIDI::Output.use 1
    @sequence = recorder.sequence
    super @timer.clockin, :interval => 16 do
      pid = fork do
        step = @sequence[@timer.counter]
        if step
          MIDI.using(@midiout) do
            channel 15
            velocity step[1]
            play step[0], step[2]*60/@timer.tempo/4
          end
        end
      end
      Process.detach pid
    end
  end

  def record
    @sequence = recorder.sequence
  end
end
=end

#t = Timer.new
#r = Recorder.new t
#loop do
  #sleep 2
  #puts t.tempo
  #puts r.sequence.inspect
#end
#player = Player.new(Recorder.new(Timer.new))
#sleep 2
#player.start
#sleep 4
#player.stop

    #@timer = t
    #@sequence = Array.new @timer.length
    #recorder = MIDIEye::Listener.new(@midiin)
    #recorder.listen_for(:class => [MIDIMessage::NoteOn, MIDIMessage::NoteOff]) do |event|
    #recorder.listen do |event|
        #puts event.inspect #unless even.class == MIDIMessage::ControlChange
=begin
      if event.class == MIDIMessage::NoteOn
        @opennotes[event[:message].note] = [event[:message], @timer.rec_counter]
      elsif event.class == MIDIMessage::NoteOff
        onmessage = @opennotes[event[:message].note].first
        start = @opennotes[event[:message].note].last
        dur = @timer.rec_counter - start
        @sequence[start] = [onmessage.note, onmessage.velocity, dur]
      end
=end
    #end
    #recorder.run#(:background => true)
#@midiin =  UniMIDI::Input.use 1
=begin
AlsaRawMIDI::Input.last.open do |input|
loop do
  sleep 0.01
  data = input.gets
  puts data #unless data.first[:data].first == 191 ## cc chan 16
  #puts data.inspect
end
=end

require "rtmidi"
midiin = RtMidi::In.new

puts "Available MIDI input ports"
midiin.port_names.each_with_index{|name,index| puts "  ##{index+1}: #{name}" }

midiin.set_callback do |byte1, byte2, byte3|  
  puts "#{byte1} #{byte2} #{byte3}"
end

puts "Listening for MIDI messages..."
puts "Ctrl+C to exit"

midiin.open_port(1)

sleep # prevent Ruby from exiting immediately
