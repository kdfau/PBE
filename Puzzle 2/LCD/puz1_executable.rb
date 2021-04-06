require 'i2c'
require_relative 'display.rb'
require_relative 'version.rb'

def puzzle1(text)  	
    display = I2C::Drivers::LCD::Display.new('/dev/i2c-1', 0x27, rows=20, cols=4)    
    #display.text(" Type something ;) ", 0)
    display.clear
	    if text.length < 20
                   display.text(text,0)
            elsif text.length < 40
                   display.text(text[0..19], 0)
                   display.text(text[20..39], 1)
            elsif text.length < 60
                   display.text(text[0..19], 0)
                   display.text(text[20..39], 1)
                   display.text(text[40..59], 2)
            else
                   display.text(text[0..19], 0)
                   display.text(text[20..39], 1)
                   display.text(text[40..59], 2)
                   display.text(text[60..79], 3)
	    end
    def clearDisplay
	display = I2C::Drivers::LCD::Display.new('/dev/i2c-1', 0x27, rows = 20, cols = 4)
	display.clear
    end
end


