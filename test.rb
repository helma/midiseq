require_relative "seq.rb"

@input = UniMIDI::Input.first.open

mbase = Instrument.new 1,9
brute = Instrument.new 0,15
mm3 = Instrument.new 0,2

#bass = Loop.new 0, 15, ["C2","G3","E3","C4"], [1,1,0,1,0,0]
#kick = Loop.new 1, 9, "C2",  [1,0,0,0]
#snr =  Loop.new 0, 2, "E4",  [0,0,0,0,1,0,0,0]
#hh =   Loop.new 0, 2, "D#4", [0,0,1,0]
bass = Loop.new brute, ["C2","G3","E3","C4"], [1,1,0,1,0,0]
kick = Loop.new mbase, "C2",  [1,0,0,0]
snr =  Loop.new mm3, "E4",  [0,0,0,0,1,0,0,0]
hh =   Loop.new mm3, "D#4", [0,0,1,0]

#=begin
score = [
  [2,  [kick]],
  [2, [kick,bass]],
  [8, [kick,bass,hh]],
  [4,  [bass,hh]]
]
#=end
#score = [ [32,[kick,snr,hh ]]]
score = {
  0 => kick,
  8 => hh,
  16 => 

song = Song.new 132, score
song.loop 8, 8
song.start
