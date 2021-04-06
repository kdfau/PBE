require 'gtk3'
require_relative 'puz1_executable.rb'

def destroy
        Gtk.main_quit
end

def app_puz2
	#Creem una finestra
	window = Gtk::Window.new(:toplevel)
	window.title = "LCD DISPLAY: PUZZLE 2"
	window.border_width = 10
	window.signal_connect('delete_event') { destroy }
	window.set_size_request(250, 150)

	#Creem una quadricula i la posem dins la finestra
	grid = Gtk::Grid.new	
	window.add(grid)

	#Creem un quadre de text
	textview = Gtk::TextView.new
	textview.editable =  true
	textview.set_size_request 125, 75 
	textview.cursor_visible =  true
	textview.pixels_above_lines = 5
	textview.pixels_below_lines = 5
	textview.pixels_inside_wrap = 5
	textview.left_margin = 10
	textview.right_margin = 10
	textview.buffer.text = "Write something! Change me! Please!"

	#Afegim el quadre a la quadricula
	grid.attach(textview, 0, 0, 2, 1)

	#scrolled_win = Gtk::ScrolledWindow.new
	#scrolled_win.border_width = 5
	#scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
	#scrolled_win.add(textview)

	#Creem i afegim un botó per a mostrar el que hem escrit a la LCD
	display_button = Gtk::Button.new :label => 'Display'
	display_button.set_size_request 125,35
	display_button.set_tooltip_text "Display into LCD"
	display_button.signal_connect "clicked" do
		puzzle1(textview.buffer.text)
	end

	grid.attach(display_button, 0, 1, 1, 1)

	#Creem i afegim un botó per netejar la pantalla LCD
	clear_button = Gtk::Button.new :label => 'Clear'
	clear_button.set_size_request 125,35
	clear_button.set_tooltip_text "Clear screen"
	clear_button.signal_connect "clicked" do
		clearDisplay
	end

	grid.attach(clear_button, 1, 1, 1, 1)

	window.show_all
 
end
 
app_puz2
Gtk.main


