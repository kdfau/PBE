# Author: Adrià Payet
# Release date: 10/03/2021

# Primera versió del codi
=begin
require 'open3'

class IteadPN532
	# Reads UID
	def read_uid
		nfc_out, stderr, status =  Open3.capture3("nfc-poll") # Captura el comando 'nfc-poll'
		nfc_out.each_line {|line| 		# Mira per cada linies de les llegides
			if line.include? ("UID") 	# 	si s'hi inclou 'UID'
				uid=line.strip 
				return extreureUID(uid)
			end
		}
		return "No s'ha pogut detectar"	# En cas d'error, aquest seria el UID retornat
	end	
	
	# Return the UID from a line
	def extreureUID(uid)
		return uid[uid.index(':')+1..-1].upcase.gsub(/\s+/, "") # Retorna string des del caràcter 
	end											  			  # ':' fins al final, en majúscules 
end															  # i sense espais en blanc

# "main", on es crea l'objecte "IteadPN532" i crida la funcio "read_uid"
if __FILE__ == $0
	rf = IteadPN532.new
	puts "Pasa la teva targeta pel lector"
	uid = rf.read_uid
	puts "El teur uid és: #{uid}"
end
=end

# Segona versió del codi, basat en l'exemple donat per 'ruby-nfc'

require 'ruby-nfc' # Llibreria més important, realitza el 'poll'
require 'logger'   # Necessaria per la linia 52, capturar errors 

class IteadPN532
	def initialize # Inicialitza la variable a ser retornada per evitar possibles errors
		@uid=""
	end
	# Reads UID
	def read_uid
		readers = NFC::Reader.all
		readers[0].poll( Mifare::Classic::Tag) do |tag| # Extret del Github de la gemma: Busca un
			begin										# Mifare Classic i guarda el seu UID
				@uid= tag.uid_hex
			rescue Exception 
				@uid= "ERROR"
			end
		return @uid.upcase		# Es retorna el UID en majúscules. En cas d'error, s'avisa.
		end	
	end
end

# 'main' on es crea l'objecte 'IteadPN532' i crida la funció 'read_uid'. S'imprimeix el UID buscat
if __FILE__ == $0
	rf = IteadPN532.new
	puts "Pasa la teva targeta pel lector"
	uid = rf.read_uid
	puts "El teur uid és: #{uid}"
end

