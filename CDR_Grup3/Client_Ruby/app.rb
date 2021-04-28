require 'gtk3'
require 'rest-client'
require 'rfid_rc522'
require_relative 'server-connect'


class RFIDWindow < Gtk::Window
	
	def initialize
		super
		#Definimos los colores para el TextView
		@blue = Gdk::RGBA::new(0,0,1.0,0.6)
		@red = Gdk::RGBA::new(1.0,0,0,0.6)
		@white = Gdk::RGBA::new(1.0,1.0,1.0,1.0)
		
		#Definimos el server      #ip publica servidor  #puerto  #archivo
		@prova = Server_HTTP.new
				
		#Configuramos los parametros de la ventana
		set_title("course_manager") #titulo
		set_position(Gtk::WindowPosition::CENTER) #posicion
		signal_connect("destroy"){Gtk.main_quit} #el programa acaba al cerrar ventana
		
		#Creamos Timer para el timeout de la sesion
		@timer = GLib::Timer.new
		@timeout = 30 #segundos
		
		#Iniciamos la primera pantalla
		screen_login
	end
	
	#SCREEN LOGIN_____________________________________________________
	#Metodo que inicia la primera pantalla donde se le pide al usuario 
	#identificarse acercando su tarjeta universitaria al receptor nfc
	#-----------------------------------------------------------------
	#VEASE: set_loginTextView, rfid_search	
	#_________________________________________________________________
	def screen_login		
		#Creamos e iniciamos variable que indica en la pantalla que estamos
		@screenNow = "login"
	
		#Creamos objeto para el lector uid
		@rfid = Rfid_rc522.new
		
		#Cambiamos el tamaño de la ventana
		resize(650,300)
		
		#Creamos TextView y configuramos sus parametros
		@textView = Gtk::TextView.new
		@textView.set_editable(false) #no editable
		@textView.set_cursor_visible(false) #sin cursor
		@textView.justification = Gtk::Justification::CENTER #texto en el centro
		@textView.override_color(:normal, @white) #color texto blanco
		set_loginTextView("Please, login with your university card", @blue) #texto por defecto
		
		#Creamos Button reset y configuramos su accion
		@button = Gtk::Button.new(:label => "Reset", :use_underline => nil, :stock_id => nil)
		@button.signal_connect("clicked") {reset_clicked} #cuando 'click' hace metodo reset_clicked
		
		#Creamos una caja vertical para los dos widgets
		@box = Gtk::Box.new(:vertical, 0) #diferente tamaño entre widgets y 0 espacio extra entre ellos
		@box.pack_start(@textView, :expand => true, :fill => false, :padding => 0) #lo añadimos a la box (arriba y altura fija)
		@box.pack_end(@button,:expand => false, :fill => false, :padding => 0) #lo añadimos a la box (abajo y altura fija)
		add(@box) #añadimos la box a la ventana
		
		#Mostramos todo
		show_all 
		
		#Iniciamos el thread de identificacion de usuario
		rfid_search	
	end
	
	#SCREEN USER INTERFACE_____________________________________________
	#Metodo que inicia la segunda pantalla donde el usuario ha accedido
	#a su sesion y se le pide que introduzca la query que desea ver
	#------------------------------------------------------------------
	#PARAMETROS: USER (string) --> NOMBRE Y APELLIDO DEL USUARIO
	#VEASE: timeout_options, container_uintinfo	
	#__________________________________________________________________
	def screen_uint (user)
		#Actualizamos el estado a la pantalla actual
		@screenNow = "uint"
	
		#Borramos los widgets de la pantalla anterior
		@box.destroy
		
		#Creamos los parametros para los widgets de esta pantalla
		@user = user
		@entryTxt = "enter your query"
		
		#Iniciamos contador timeout
		timeout_options ("start")
		@isTimeout = false
		
		#Creamos contenedor tipo tabla con los widgets
		container_uintinfo
	end
	
	#SCREEN INFORMATION______________________________________________
	#Metodo que inicia la tercera pantalla donde le muestra los datos
	#al usuario de la query pedida en la misma pantalla o anterior 
	#----------------------------------------------------------------
	#PARAMETROS: STR (string) --> QUERY PEDIDA POR EL USUARIO
	#VEASE: set_table, container_uintinfo
	#________________________________________________________________
	def screen_info (str, query)
		#Si venimos de la pantalla anterior cambia el tamaño de la ventana
		if @screenNow == "uint" then resize(800,600) end
		
		
		#Actualizamos el estado a la pantalla actual
		@screenNow = "info"
				
		#Diferenciamos los casos para cada tipo de tabla:
		#...Crea Frame que contendra la tabla y añade el titulo correspondiente
		#...Crea TreeStore con los tipos de datos de cada columna
		#...Crea vector con los titulos de cada columna
		#...Crea tabla
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
		
		#Actualizamos container
		container_uintinfo
	end
	
	#_____________________________________________________________________
	#Decide si pasar a la siguiente pantalla o que hacer en caso contrario
	#...Caso pantalla actual login:	
	#......Si el username existe pasamos siguiente pantalla
	#......Si el username no existe sacamos el warning
	#...Caso pantalla actual uint o info: 
	#......Si se ha excedido el tiempo de timeout por inactividad
	#......se vuelve a la pantalla de inicio login
	#......Si la query existe pasamos siguiente pantalla
	#......Si la query no existe sacamos el warning
	#---------------------------------------------------------------------
	#PARAMETROS: STR (string) --> QUERY PEDIDA POR EL USUARIO
	#VEASE: timeout_options, container_uintinfo
	#_____________________________________________________________________
	def go_next_screen (str, query)
		case @screenNow
			when "login"
				if !str.include?("User not found, try again")
					username = str.delete '"[]' #Eliminamos lo que no sea del nombre
					screen_uint(username) #Pasamos a la siguiente pantalla
				else
					set_loginTextView("User not found, try again", @red)
				end
			when "uint", "info"
				if @isTimeout
					@logout.clicked #volver a la pantalla de login
				else 
					timeout_options ("restart") #Reseteamos tiempo de inactividad
					if !str.include?("Query not found, try again")
						screen_info(str, query) #Pasamos a la siguiente pantalla
					else
						@entry.set_text("Query not found, try again")
					end
				end
		end
	end

	#____________________________________________________________
	#Crea la tabla donde saldra la informacion de la query pedida
	#y la mete en la variable global @outputTable
	#------------------------------------------------------------
	#PARAMETROS: STR (string) ------> QUERY
	#			 HEADSTR (string) --> VECTOR CON LOS TITULOS 
	#____________________________________________________________
	def set_table (str, headStr)
										  #fila 1		      #fila 2   
		#Como el string es del tipo ["pepe","10","..."]["paula","2","..."]...
		#siendo str[0]='[' y str[1]='"' lo recorremos todo juntando los char que estan entre comillas
		#y cada dato obtenido lo ponemos en la siguiente posicion del Iter (de @TreeStore) para así 
		#formar la fila correspondiente 
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
		
		#Creamos TreeView con la TreeStore configurada arriba
		@outputTable = Gtk::TreeView.new(@treestore)
		@outputTable.selection.mode = Gtk::SelectionMode::NONE
		@outputTable.set_enable_grid_lines(Gtk::TreeViewGridLines::HORIZONTAL) #grid lines ON
		
		#Creamos y añadimos una columna con su CellRendererText por cada titulo
		headStr.each_with_index do |st,k|
			renderer = Gtk::CellRendererText.new
			renderer.set_alignment(Pango::Alignment::LEFT) #alineado del texto izquierda
			col = Gtk::TreeViewColumn.new(st, renderer, :text => k)
			@outputTable.append_column(col)
		end	
	end
	
	#_______________________________________________________________________
	#Creamos todos los widgets compartidos de las pantallas USER INTERFACE e
	#INFORMATION y los metemos en un contenedor tipo Table
	#-----------------------------------------------------------------------
	#VEASE: timeout_options, container_uintinfo
	#_______________________________________________________________________
	def container_uintinfo
		#Creamos las opciones para Table
		@options1 = Gtk::AttachOptions::EXPAND
		@options2 = Gtk::AttachOptions::FILL
		@options3 = Gtk::AttachOptions::SHRINK
		@options4 = Gtk::AttachOptions::EXPAND|Gtk::AttachOptions::FILL
		
		if @screenNow == "uint"
			@table = Gtk::Table.new(2,2,false) # rows, columns, homogeneous
			@table.set_column_spacing(450) #espacio entre columnas
			@table.set_row_spacings(10) #espacio entre filas
		else
			@table.destroy #destruimos tabla y widgets anteriores
			@table = Gtk::Table.new(3,2,false) # rows, columns, homogeneous
			@titulo.add_child(@outputTable) #metemos la tabla en el Frame
			@titulo.set_label_align(0.5,1)
			@table.attach(@titulo, 0, 2, 2, 3, @options4, @options4, 20, 50) #metemos Frame en la Table
			@table.set_column_spacing(450) #espacio entre columnas
			@table.set_row_spacings(1) #espacio entre filas
		end
		
		#Creamos el Label para el nombre
		username = Gtk::Label.new("Welcome "+@user)
		
		#Creamos boton de logout
		@logout = Gtk::Button.new(:label => "Logout", :use_underline => nil, :stock_id => nil)
		@logout.signal_connect("clicked") { @table.destroy
										    timeout_options ("stop")
										    screen_login} #cuando 'click' vuelve a screen_login
		
		#Creamos el Entry donde el usuario escribe
		@entry = Gtk::Entry.new
		@entry.set_text(@entryTxt)
		
		#Cuando se pulsa intro, si no se ha superado el tiempo de timeout
		#pedimos al servidor la query solicitada en el Entry 
		@entry.signal_connect("activate") { if !@isTimeout
												@entryTxt = @entry.text
												timeout_options ("reset")
												input_server(@entryTxt)
											else
												go_next_screen(nil)
											end
										  }
					#  child,   x1, x2, y1, y2, x-opt,     y-opt,    xpad, ypad
		@table.attach(username, 0,  1,  0,  1, @options3, @options3, 10,   0)
		@table.attach(@logout,   1,  2,  0,  1, @options3, @options3, 5,    6)
		@table.attach(@entry,    0,  2,  1,  2, @options2, @options1, 10,    0)
		
		#La metemos en la window y mostramos todo
		add(@table)
		show_all
	end
		
	#__________________________________________________________
	#Cuando se haga 'click' en reset se vuelve al texto inicial 
	#y se vuelve a esperar la entrada de una tarjeta
	#----------------------------------------------------------
	#VEASE: set_loginTextView, rfid_search
	#__________________________________________________________
	def reset_clicked
		set_loginTextView("Please, login with your university card", @blue)
		rfid_search
	end
	 
	#_______________________________________________________
	#Sobreescribe el texto y cambia el color del fondo
	#-------------------------------------------------------
	#PARAMETROS: TEXT (string) ------> TEXTO A SOBREESCRIBIR
	#			 COLOR (Gdk::RGBA) --> COLOR DEL FONDO
	#_______________________________________________________
	def set_loginTextView (text, color)
		@textView.buffer.text = "\n"+text+"\n" #en el medio
		@textView.override_background_color(:normal,color)
	end

	#___________________________________________________________________
	#Crea un thread que cuando detecta una tarjeta Mifare Classic envia
	#su UID en mayusculas al servidor y actúa según el String recibido
	#-------------------------------------------------------------------
	#VEASE: input_server
	#___________________________________________________________________
	def rfid_search
		t = Thread.new {input_server("students?uid="+@rfid.read_uid)}
	end
		
	#__________________________________________________________________________
	#Crea un thread que se conecta al servidor y actúa según el String recibido
	#--------------------------------------------------------------------------
	#PARAMETROS: QUERY (string) --> QUERY A PEDIR
	#VEASE: go_next_screen
	#__________________________________________________________________________
	def input_server (query)
		t = Thread.new {go_next_screen(@prova.get_server(query),query)}
	end
	
	#_____________________________________________________________________
	#Decide si pasar a la siguiente pantalla o que hacer en caso contrario
	#...Caso iniciar contador:	
	#......Crea un Thread que estara constantemente mirando si se pasa el
	#......tiempo de timeout y si es así pasa a la pantalla de login
	#...Caso resetear contador: 
	#......Actualiza la referencia de inicio del contador al tiempo actual
	#...Caso detener contador: 
	#......Lo detiene
	#---------------------------------------------------------------------
	#PARAMETROS: CONFIG (string) --> FUNCION A CONFIGURAR EN EL TIMER
	#_____________________________________________________________________
	def timeout_options (config)
		Thread.report_on_exception = false #descartamos las exception del Thread
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
