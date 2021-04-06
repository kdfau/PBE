require 'gtk3'
require 'rfid_rc522'

class Puzzle2 < Gtk::Window

    def initialize
        super
			init_ui
		end	
		
	def init_ui
	
		set_title  "Puzzle 2"
		signal_connect "destroy" do 
            Gtk.main_quit 
        end 

		#Creem un grid, que ens ajudarà a situar el label i el botó a on volguem
		grid = Gtk::Grid.new 
		add(grid)
		
		#Creem un label
        @label = Gtk::Label.new 
        @label.set_text("Please, login with your university card")
		@label.set_size_request(500,100) 
		@label.override_background_color(0 , Gdk::RGBA::new(0, 0, 1.0, 1.0)) #Amb això fem que el fons del label sigui de color blau
		@label.override_color(0 , Gdk::RGBA::new(1.0, 1.0, 1.0, 1.0))	#Lletres de color blanc 
		grid.attach(@label,0,0,1,1) #Aquí li estem dient que volem que el label estigui a la columna 0 i la fila 0 i que ocupi 1 columna i 1 fila
		
		#Creem el botó clear
		button = Gtk::Button.new(:label => "Clear") 
		button.signal_connect("clicked") {clear}
		grid.attach(button, 0, 1, 1, 1) #El botó va a la columna 0, fila 1 i ocupa 1 columna i 1 fila
		
		#Col·loquem la finestra al centre de la pantalla i establim l'espai al contorn de la finestra
        set_window_position(:center)   
        set_border_width 10
        
        #Cridem la funció que invoca el thread
        @rf = Rfid_rc522.new
		rc522		
		
		#Fem que ens ho mostri    
        show_all
         
    end
    
	
    def rc522	#Aquesta funció és un thread auxiliar que s'executarà cada vegada que volem llegir l'UID
    thr = Thread.new{
		uid = @rf.read_uid
		@label.set_text("uid: #{uid}")
		@label.override_background_color(0 , Gdk::RGBA::new(1.0, 0, 0, 1.0)) #Color vermell
		}     		
    end
    
    def clear	#És el que s'executarà quan clickem el botó clear
		@label.set_text("Please, login with your university card")
		@label.override_background_color(0 , Gdk::RGBA::new(0, 0, 1.0, 1.0)) #Color blau		
		rc522
    end
end

window = Puzzle2.new  
Gtk.main
