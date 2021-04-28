require 'net/http'
require 'uri'

class Server_HTTP
	def initialize 
		@uri = URI::HTTP.build(host: '192.168.68.102', port: '80')
	end

	#Retorna la query solicitada al servidor
	def get_server (query)
			
		@path = '/' +query
	
		res = Net::HTTP.get_response('192.168.68.102', @path)
		
		return res.body if res.is_a?(Net::HTTPSuccess)
	end 
end
