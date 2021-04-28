require 'gtk3'
require 'rest-client'
require 'rfid_rc522'
require_relative 'server-connect'


class RFIDWindow < Gtk::Window
	
	def initialize
		super
		#Definim els colors pel TextView
		@blue = Gdk::RGBA::new(0,0,1.0,0.6)
		@red = Gdk::RGBA::new(1.0,0,0,0.6)
		@white = Gdk::RGBA::new(1.0,1.0,1.0,1.0)
		
		#Definim el server      #ip pública servidor  #port  #arxiu 
		@prova = Server_HTTP.new
				
		#Configurem els paràmetres de la finestra
		set_title("course_manager") #títol
		set_position(Gtk::WindowPosition::CENTER) #posició
		signal_connect("destroy"){Gtk.main_quit} #el programa acaba al tancar la finestra
		
		#Creem el Timer per el timeout de la sessió
		@timer = GLib::Timer.new
		@timeout = 30 #segons
		
		#Iniciem la primera pantalla
		screen_login
	end
	
	#SCREEN LOGIN_____________________________________________________
	#El métode que inicia la primera pantalla a on es demana al usuari
	#que d'identifiqui acostant la seva targeta al receptor nfc
	#-----------------------------------------------------------------
	#_________________________________________________________________
	def screen_login		
		#Cream i iniciem la variable que indica a la pantalla que estem
		@screenNow = "login"
	
		#Creem l'objecte per al lector uid
		@rfid = Rfid_rc522.new
		
		#Cambiem el tamany de la finestra
		resize(650,300)
		
		#Creem el TextView i configurem els seus paràmetres
		@textView = Gtk::TextView.new
		@textView.set_editable(false) #no editable
		@textView.set_cursor_visible(false) #sense cursor
		@textView.justification = Gtk::Justification::CENTER #posar el text al centre
		@textView.override_color(:normal, @white) #color text blanc
		set_loginTextView("Please, login with your university card", @blue) #text per defecte
		
		#Creem Button reset i el configurem
		@button = Gtk::Button.new(:label => "Reset", :use_underline => nil, :stock_id => nil)
		@button.signal_connect("clicked") {reset_clicked} #quan el cliquem executa el mètode reset_clicked
		
		#Creem una caixa vertical pels dos widgets
		@box = Gtk::Box.new(:vertical, 0) 
		@box.pack_start(@textView, :expand => true, :fill => false, :padding => 0) 
		@box.pack_end(@button,:expand => false, :fill => false, :padding => 0)
		add(@box) #Posem la caixa a la finestra
		
		#Ho ensenyem en pantalla
		show_all 
		
		#Iniciem el thread d'identificació de l'usuario
		rfid_search	
	end
	
	#SCREEN USER INTERFACE_____________________________________________
	#El métode que inicia la segona pantalla a on l'usuari accedeix
	#a la seva sessió i se li demana que introdueixi el que vol veure
	#__________________________________________________________________
	def screen_uint (user)
		#Actualitzem la apantalla actual
		@screenNow = "uint"
	
		#Borrem els widgets de la pantalla anterior
		@box.destroy
		
		#Creem els paràmetres per els widgets de la pantalla
		@user = user
		@entryTxt = "enter your query"
		
		#Iniciem el comptador timeout
		timeout_options ("start")
		@isTimeout = false
		
		#Creem un container de tipo taula amb els widgets
		container_uintinfo
	end
	
	#SCREEN INFORMATION________________________________________________
	#El métode que inicia la tercera pantalla a on es mostren les dades
	#al usuari de la query perduda a la mateixa pantalla (o l'anterior) 
	#__________________________________________________________________
	def screen_info (str, query)
		#Si venim de la segona pantalla, canviem el seu tamany
		if @screenNow == "uint" then resize(800,600) end
		
		#Actualitzem l'estat de la pantalla actual
		@screenNow = "info"
				
		#Diferenciem els casos de cada tipus de taula i ho creem
		if query.include? "timetables"
			@titulo = Gtk::Frame.new("timetables")
			@treestore = Gtk::TreeStore.new(String, String, String, String)
		
			headStr = ["day", "hour", "subject", "room"]
			set_table(str, headStr)
			
		elsif query.include? "marks"
			@titulo = Gtk::Frame.new("marks")
			@treestore = Gtk::TreeStore.new(String, String, String)
		
			headStr = ["subject", "name", "mark"]
			set_table(str, headStr)
			
		elsif query.include? "tasks"
			@titulo = Gtk::Frame.new("tasks")
			@treestore = Gtk::TreeStore.new(String, String, String)
			
			headStr = ["date", "subject", "name"]
			set_table(str, headStr)
			
		end
		
		#Actualitzem el container
		container_uintinfo
	end
	
	#_____________________________________________________________________
	#Decidim si pasar a la següent pantalla o que fer
	#...Si la pantalla actual és el login:	
	#......Si el username existeix -> passem a la següent pantalla
	#......Si el username no existeix -> warning
	#...Si la pantalla actual és la de uint o info: 
	#......Si s'ha exedit el timeout -> pantalla d'inici
	#......Si la query existeix -> següent pantalla pasamos siguiente pantalla
	#......Si la query no existeix -> warning
	#_____________________________________________________________________
	def go_next_screen (str, query)
		case @screenNow
			when "login"
				if !str.include?("User not found, try again")
					username = str.delete '"[]' #Eliminem el que no sigui el nom
					screen_uint(username) #Passem a la següent pantalla
				else
					set_loginTextView("User not found, try again", @red)
				end
			when "uint", "info"
				if @isTimeout
					@logout.clicked #Tornem a la pantalla de login
				else 
					timeout_options ("restart") #Resetejem el temps
					if !str.include?("Query not found, try again")
						screen_info(str, query) #Passem a la següent pantalla
					else
						@entry.set_text("Query not found, try again")
					end
				end
		end
	end

	#____________________________________________________________
	#Creem la taula a on hi sortirà l'informació de la query 
	#demanada i la posem a @outputTable
	#____________________________________________________________
	def set_table (str, headStr)
		#Recorrem la string, ajuntem el que hi ha entre les cometes i ho posem a la següent posició 
		i = 0
		while i < str.length
			parent = @treestore.append(nil)
			j = 0
			while str[i] != "]" do
				if str[i] == '"'
					i += 1
					word = 'x'
					while str[i] != '"' do
						word += str[i]
						i += 1
					end
					parent[j] = word.delete_prefix('x')+"                                "
					j += 1
				end
				i += 1
			end
			i += 1
		end
		
		#Creem un TreeView amb TreeStore 
		@outputTable = Gtk::TreeView.new(@treestore)
		@outputTable.selection.mode = Gtk::SelectionMode::NONE
		@outputTable.set_enable_grid_lines(Gtk::TreeViewGridLines::HORIZONTAL) 
		
		#Creem i afegim una columna amb el seu CellRendererText per cada títol
		headStr.each_with_index do |st,k|
			renderer = Gtk::CellRendererText.new
			renderer.set_alignment(Pango::Alignment::LEFT) 
			col = Gtk::TreeViewColumn.new(st, renderer, :text => k)
			@outputTable.append_column(col)
		end	
	end
	
	#_______________________________________________________________________
	#Creem tots els widgets compartits de les pantalles USER INTERFACE i
	#INFORMATION i els posem a un container de tipus Table
	#_______________________________________________________________________
	def container_uintinfo
		#Creem les diferents opcions de Table
		@options1 = Gtk::AttachOptions::EXPAND
		@options2 = Gtk::AttachOptions::FILL
		@options3 = Gtk::AttachOptions::SHRINK
		@options4 = Gtk::AttachOptions::EXPAND|Gtk::AttachOptions::FILL
		
		if @screenNow == "uint"
			@table = Gtk::Table.new(2,2,false) 
			@table.set_column_spacing(450) 
			@table.set_row_spacings(10) 
		else
			@table.destroy 
			@table = Gtk::Table.new(3,2,false) 
			@titulo.add_child(@outputTable) 
			@titulo.set_label_align(0.5,1)
			@table.attach(@titulo, 0, 2, 2, 3, @options4, @options4, 20, 50) 
			@table.set_column_spacing(450)
			@table.set_row_spacings(1) 
		end
		
		#creem un label pel nom
		username = Gtk::Label.new("Welcome "+@user)
		
		#Creem el botó de logout
		@logout = Gtk::Button.new(:label => "Logout", :use_underline => nil, :stock_id => nil)
		@logout.signal_connect("clicked") { @table.destroy
										    timeout_options ("stop")
										    screen_login} #Quan cliquem tornem a la pàgina de login
		
		#Creem l'entrada on l'usuari escriu
		@entry = Gtk::Entry.new
		@entry.set_text(@entryTxt)
		
		#Si quan polsem intro no hem superat el timeout, demanem la query solicitada
		@entry.signal_connect("activate") { if !@isTimeout
												@entryTxt = @entry.text
												timeout_options ("reset")
												input_server(@entryTxt)
											else
												go_next_screen(nil)
											end
										  }
		@table.attach(username, 0,  1,  0,  1, @options3, @options3, 10,   0)
		@table.attach(@logout,   1,  2,  0,  1, @options3, @options3, 5,    6)
		@table.attach(@entry,    0,  2,  1,  2, @options2, @options1, 10,    0)
		
		#La posem a la finestra i ho mostrem
		add(@table)
		show_all
	end
		
	#__________________________________________________________
	#Quan cliquem el reset tornem al text inicial
	#i tornem a esperar la lectura d'una targeta
	#__________________________________________________________
	def reset_clicked
		set_loginTextView("Please, login with your university card", @blue)
		rfid_search
	end
	 
	#_______________________________________________________
	#Sobreescriu el text i canvia el color de fons
	#_______________________________________________________
	def set_loginTextView (text, color)
		@textView.buffer.text = "\n"+text+"\n" #en el medio
		@textView.override_background_color(:normal,color)
	end

	#___________________________________________________________________
	#Creem un thread que quan detecta una targeta Mifare Classic envia
	# el seu UID en majúscules al servidor i actua segons el string rebut
	#___________________________________________________________________
	def rfid_search
		t = Thread.new {input_server("students?uid="+@rfid.read_uid)}
	end
		
	#__________________________________________________________________________
	#Creem un thread que es conecta al servidor i actua depenent del string rebut
	#__________________________________________________________________________
	def input_server (query)
		t = Thread.new {go_next_screen(@prova.get_server(query),query)}
	end
	
	#_____________________________________________________________________
	#Decideix si passar a la següent pantalla o si no:
	#...Iniciar comptador:	
	#......Crea un Thread que mirarà si es passa el temps de timeout i, 
	#......en tal cas, tornarà al login
	#...Resetejar el comptador: 
	#......Actualiza la referència d'inici del comptador al temps actual
	#...Parem el comptador: 
	#......El para
	#_____________________________________________________________________
	def timeout_options (config)
		Thread.report_on_exception = false 
		case config
			when "start"
				@isTimeout = false
				@timer.start
				@timestart = @timer.elapsed[0]
				t = Thread.new {loop do
									break if (@timer.elapsed[0] - @timestart) > @timeout
								end
								@timer.stop
								@isTimeout = true
								@entry.activate
							   }
			when "reset"
				@timestart = @timer.elapsed[0]
			when "stop"
				@timer.stop
		end
	end
end

if __FILE__ == $0
	app = RFIDWindow.new
	Gtk.main
end
