

require 'mfrc522' #Llibreria necessària per tenir accés al perifèric desde la Raspberry

class Rfid_rc522
    def read_uid 	#Aquesta funció definida és l'encarregada de llegir l'identificador i tornar-lo en cas de que no hi hagi error
        r = MFRC522.new		#Creem l'objecte MFRC522
        begin
			r.picc_request(MFRC522::PICC_REQA)	#Passa ek PICC de l'estat HALT o IDLE a l'estat ACTIU
            uid, sak = r.picc_select	#Llegeix l'uid
        rescue CommunicationError => e
			abort "Error communicating PICC: #{e.message}"
        end
        return uid
    end
end



if __FILE__ == $0	#Aquí creem l'objecte Rfid_rc522 i cridem la funció creada per tal que s'imprimeixi l'identificador

	rf = Rfid_rc522.new
	confirmacio=""
	while confirmacio!="s"
		puts"Quan tingui la seva targeta sobre el sensor, introdueixi la tecla 's':"
		confirmacio= gets.chomp
	end
	uid=rf.read_uid
	puts "El seu identificador es: "
	puts "%02X%02X%02X%02X" % uid

end
