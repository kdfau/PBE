require 'gtk3' 
require 'thread'
require_relative 'elechouse_Youssef.rb'

BLUE = Gdk::RGBA.new(0,0,1,0.65)
RED = Gdk::RGBA.new(1,0,0,0.65)
WHITE = Gdk::RGBA.new(1,1,1,1)

TEXTO_INICIAL="Please, login with your university card"

class Rfid_Reader
	def initialize(reader,handler)
		@reader=reader
		@handler=handler
	end
	def read_uid
		thread=Thread.new{
			uid=@reader.read_uid
			puts "#{uid}"
			GLib::Idle.add{
				@handler.call("#{uid}")
			}
		}
	end	
end
	
#Creamos la ventana
 window=Gtk::Window.new("Rfid_gtk.rb")
 window.set_border_width(10)
 window.set_position(Gtk::WindowPosition::CENTER)
 window.signal_connect("delete_event") do
 	Gtk.main_quit
	false
 end

#Creamos la caja
 vbox=Gtk::VBox.new(false,5)

#Añadimos la caja a la ventana
 window.add(vbox)

#Creamos la etiqueta
 $tag=Gtk::Label.new(TEXTO_INICIAL)
 $tag.override_background_color(:normal,BLUE)
 $tag.override_color(:normal,WHITE)
 $tag.set_size_request(350,65)

#Añadimos la etiqueta a la caja
 vbox.add($tag)

#Creamos el boton
 button=Gtk::Button.new(:label=>"Clear")

#Añadimos el boton al contenedor
 vbox.add(button)
		
 button.signal_connect("clicked") {|w|
	#Mostramos la etiqueta inicial
	 $tag.set_text(TEXTO_INICIAL)
	 $tag.override_background_color(:normal, BLUE)
	
	#Leemos uid
         $rfid.read_uid
 }
 
 def update_window(uid)
 	#Mostramos el uid	
	 $tag.set_text("UID: #{uid}")
	 $tag.override_background_color(:normal, RED)
 end
 
 $rfid=Rfid_Reader.new(Rfid_PN532.new, method(:update_window))
 $rfid.read_uid
	
#Mostramos la ventana		
 window.show_all
 Gtk.main