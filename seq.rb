require "micromidi"
require "topaz"

class Device
  def initialize nr
    @midi = MIDI.using(UniMIDI::Output.use(nr))
  end
  def play note, bpm
    @midi.channel note.instrument.channel
    @midi.velocity note.vel
    @midi.play note.note, note.dur*60.0/bpm/4
  end
end

class Instrument
  attr_accessor :device, :channel
  def initialize dev, chan
    @device = dev
    @channel = chan
  end
end

class Note
  attr_accessor :instrument, :note, :vel, :dur
  def initialize instrument, note, vel, dur
    @instrument = instrument
    @note = note
    @vel = vel
    @dur = dur
  end
end

class Loop

  attr_accessor :instrument
  
  def initialize instrument, notes="C3", pattern=[1,0,0,0], velocities=100, durations=1
    @instrument = instrument
    @pattern = pattern.collect{|s| s.to_i > 0 ? true : false }
    @notes = [notes].flatten
    @velocities = [velocities].flatten
    @durations = [durations].flatten
  end

  def note counter
    ni = counter % @notes.length
    pi = counter % @pattern.length
    vi = counter % @velocities.length
    di = counter % @durations.length
    @pattern[pi] ? Note.new(@instrument, @notes[ni], @velocities[vi], @durations[di]) : nil
  end

end

class Song < Topaz::Tempo

  def initialize bpm, score
    @counter = 0
    @loop_start = 0
    @score = []
    @instruments = []
    @devices = [0,1].collect{|i| Device.new i}
    score.each do |row|
      (row.first*16).times do
        @score << row.last
      end
    end
    @loop_end = @score.size
    @bpm = bpm

    at_exit do
      self.stop
      @devices.each {|d| d.all_notes_off; d.close }
    end

    t=Time.now
    super bpm, :interval => 16 do
      Thread.new { self.step }
      diff = Time.now-t - 60.0/@bpm/4.0
      puts @counter, diff if diff.abs > 0.001 
      t=Time.now
    end
  end

  def loop start, length
    @loop_start = start*4
    @loop_end = @loop_start + length*4
    @counter = @loop_start
    @loop = true
  end

  def step
    @counter = @loop_start if @loop and @counter >= @loop_end
    @score[@counter].each do |l|
      Thread.new do
        note = l.note(@counter)
        @devices[note.instrument.device].play note, @bpm if note
      end
    end
    @counter += 1
    self.stop if @counter >= @score.length
  end

  def record instrument
=begin
    @devices(instrument.device).open do |input|
      puts "recording #{instrument.inspect}"
      loop do
        m = input.gets
        puts(m)
      end

    end
=end
    seq = []
    recorder = MIDIEye::Listener.new(input)
    recorder.listen_for(:class => [MIDIMessage::NoteOn, MIDIMessage::NoteOff]) do |event|
      if event.class == MIDIMessage::NoteOn
        seq[@counter] = Note.new instrument, event[:message].note, event[:message].velocity, 0
      elsif event.class == MIDIMessage::NoteOff
        dur = @counter-seq.length-1
        seq.last.duration = dur
      end
    end
    recorder.run(:background => true)
    #transpose.join # join the background thread later
  end

end

