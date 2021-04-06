require 'ruby-nfc'
require 'logger'

class Rfid_PN532
  #constructor
  def initialize
      puts "\nPlease, login with your university card"
  end
 
  #return uid in hex str
  def read_uid
    readers=NFC::Reader.all
	readers[0].poll(Mifare::Classic::Tag) do |tag|
	  begin
	  	return "#{tag.uid_hex.upcase}"
	  end
	end
  end
end

if __FILE__ == $0
    rf = Rfid_PN532.new
    uid = rf.read_uid
    puts "\nUID: #{uid}\n\n"
end

