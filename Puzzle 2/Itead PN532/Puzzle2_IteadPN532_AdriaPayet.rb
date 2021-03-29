# Puzzle2_IteadPN532_AdriaPayet.rb
#  Adrià Payet
#  Curs 2020/21P PBE

require 'gtk3'
require_relative 'Puzzle1_IteadPN532_AdriaPayet.rb'
require 'thread'

def app_main
   # Es crea la finestra
	window = Gtk::Window.new("rfid_gtk.rb")
	window.set_border_width(10)
	window.signal_connect('destroy') { Gtk.main_quit }
   # Es crea la caixa on apareixen el label i el botó
	box = Gtk::Box.new(:vertical,6)
    window.add(box)
   # Es crea el Label on apareix el UID 
	$signboard = Gtk::Label.new("Please, login with your university card")
	$signboard.override_color(:normal, Gdk::RGBA::new(1.0,1.0,1.0,1.0))
	$signboard.set_size_request(350,55)
	box.add($signboard)	
   # Colors dels signboarnd
	$blau = Gdk::RGBA::new(0.5,0.5,1.0,1.0)
	$vermell = Gdk::RGBA::new(1.0,0.5,0.5,1.0)    
   # Es crea el botó de "CLEAR"
    button = Gtk::Button.new(label: 'Clear')
    button.signal_connect('clicked') { clear_clicked }
    box.pack_start(button)
    
   # Gestiona canvi d'estat depenent de la situació
    def update_state(txt)
	   # Cas botó "CLEAR", s'inicia Poll
		if txt==nil
			$signboard.set_label("Please, login with your university card")
			$signboard.override_background_color(:normal, $blau)
			Thread.new{
				rf = IteadPN532.new
				update_state(rf.read_uid)
			}
	   # Cas resposta del Poll, es mostra per pantalla el UID
		else
			$signboard.set_label("uid: #{txt}")
			$signboard.override_background_color(:normal, $vermell)
		end
    end

   # Si es fa click al botó "CLEAR", s'inicia poll
	def clear_clicked
		update_state(nil)
	end
	
   # Inicialitza el primer poll de tots
    update_state(nil) 
   # Visualitza finestra amb els components
	window.show_all
end

# main
if __FILE__ == $0
	app_main
	Gtk.main
end

