require "diamond"
@output = UniMIDI::Output.use(:first)

opts = {
  :interval => 7,
  :midi => @output,
  :range => 4,
  :rate => 8,
  :output_channel => 15
}
@arp = Diamond::Arpeggiator.new(175,opts)

chord = ["C3", "G3", "Bb3", "A4"]

@arp << chord

#arp.start
