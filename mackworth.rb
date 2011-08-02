#!/usr/bin/jruby -w
# -*- ruby -*-

require 'csv'
require 'set'
require 'pathname'
require 'spacebar_listener'

include Java

import java.awt.Color
import java.awt.RenderingHints
import java.awt.Toolkit
import java.awt.event.KeyEvent
import java.awt.geom.Ellipse2D
import javax.swing.JButton
import javax.swing.JFrame
import javax.swing.JMenu
import javax.swing.JMenuBar
import javax.swing.JMenuItem
import javax.swing.JOptionPane
import javax.swing.JPanel

# Log.level = Log::DEBUG

$testing = false
$param_num = $testing ? 1 : 0   # 0 == actual; 1 == testing

module SwingUtil

  def self.included base
    @@pixels_per_mm = Toolkit.default_toolkit.screen_resolution.to_f / 25.4
  end

  def mm_to_pixels length_in_mm
    length_in_mm * @@pixels_per_mm
  end

end


class MackworthTestResultsFile 

  CSV_HEADER_FIELDS = [ "userid", "duration", "answered", "is_long", "accurate" ]

  CSV_FILE_NAME = 'mackworth.csv'

  def self.home_directory
    home = ENV['HOME']
    unless home
      home = (ENV['HOMEDRIVE'] || "") + (ENV['HOMEPATH'] || "")
    end
    
    homedir = ENV['HOME'] || (ENV['HOMEDRIVE'] + ENV['HOMEPATH'])
    Pathname.new(homedir)
  end

  def initialize
    @csv_file = self.class.home_directory + CSV_FILE_NAME
    
    @csv_lines = @csv_file.exist? ? CSV.read(@csv_file.to_s) : [ CSV_HEADER_FIELDS ]
  end

  def addlines lines
    @csv_lines.concat lines
  end

  def write
    @csv_lines.each do |line|
      puts line
    end

    CSV.open @csv_file.to_s, 'w' do |csv|
      @csv_lines.each do |line|
        csv << line
      end
    end
  end
end

class MackworthTestParameters

  SHORT_LINE_LENGTH  = [84,     84][$param_num] # mm
  LONG_LINE_FACTOR   = [1.15, 1.50][$param_num]
  LONG_LINE_LENGTH   = (SHORT_LINE_LENGTH * LONG_LINE_FACTOR).to_i
  
  DISPLAY_DURATION   = [1000, 3000][$param_num] # ms
  LINE_DURATION      = [300,  1000][$param_num] # ms
  FLICKER_DURATION   = 10                       # ms
  FLICKER_ITERATIONS = (LINE_DURATION.to_f / FLICKER_DURATION).to_i
  
  LINE_THICKNESS = 4
  DISTANCE_BETWEEN_LINES = 25

  LINE_COLOR = Color.new 50, 50, 50

  INTRO_DURATION = 5000         # ms

  # $$$ need confirmation about how many iterations to run here:
  ITERATIONS_PER_TEST = [10, 4][$param_num]
  
  # % of iterations to show long lines:
  LONGITERS   = ITERATIONS_PER_TEST * 0.25

end


class MainPanel < JPanel
  include SwingUtil

  attr_accessor :renderer
  
  def initialize
    super()

    @renderer = nil
    @background_color = Color.new 250, 250, 250
  end

  def paintComponent g
    super

    g.background = @background_color

    rh = RenderingHints.new RenderingHints::KEY_ANTIALIASING, RenderingHints::VALUE_ANTIALIAS_ON
    
    rh.put RenderingHints::KEY_RENDERING, RenderingHints::VALUE_RENDER_QUALITY
    
    g.rendering_hints = rh

    dim = size

    clear_screen g, dim

    if @renderer
      @renderer.render g, dim
    end
  end

  def clear_screen g, dim
    g.clear_rect 0, 0, dim.width, dim.height
  end

end


class LineDrawer
  include SwingUtil

  def draw_centered_line gdimary, y, length_in_mm
    g   = gdimary[0]
    dim = gdimary[1]
  
    g.color = MackworthTestParameters::LINE_COLOR
    
    len   = mm_to_pixels length_in_mm
    ctr_x = dim.width  / 2
    x     = ctr_x - len / 2

    g.fill_rect x, y, len, MackworthTestParameters::LINE_THICKNESS
  end

  def draw_text g, dim, text
    g.font = java.awt.Font.new "Times New Roman", java.awt.Font::PLAIN, 18

    ctr_x = dim.width / 2
    ctr_y = dim.height / 2

    x = (ctr_x * 0.80).to_i
    y = (ctr_y * 0.60).to_i
    
    text.each_with_index do |line, idx|
      g.draw_string line, x, y + (idx * 30)
    end
  end

end


class LineRenderer < LineDrawer

  attr_accessor :length_in_mm

  def initialize test
    @test = test
    @dist_from_y = mm_to_pixels(MackworthTestParameters::DISTANCE_BETWEEN_LINES) / 2
  end

  def random_length base_len
    base_len + (rand(3) - 2) * rand(10)
  end

  def render g, dim
    return unless @test.show_lines

    g.color = MackworthTestParameters::LINE_COLOR
    
    length_in_mm = @test.current_line_length_in_mm
    ctr_y        = dim.height / 2

    [ -1, 1 ].each do |fact|
      draw_centered_line [ g, dim ], ctr_y + (fact * @dist_from_y), random_length(length_in_mm)
    end
  end

end


class IntroRenderer < LineDrawer

  def initialize test
    @text = Array.new
    
    @text << "For each of the following screens,"
    @text << "press the spacebar when you see the longer"
    @text << "pair of lines."
    @text << ""
    @text << "Below are the shorter and longer lines."
  end

  def render g, dim
    draw_text g, dim, @text

    ctr_y = dim.height / 2

    draw_centered_line [ g, dim ], (ctr_y * 1.2).to_i, MackworthTestParameters::SHORT_LINE_LENGTH
    draw_centered_line [ g, dim ], (ctr_y * 1.4).to_i, MackworthTestParameters::LONG_LINE_LENGTH
  end

end


class OutroRenderer < LineDrawer

  def initialize test
    @text = Array.new
    
    @text << "End of test."
    @text << ""
  end

  def render g, dim
    draw_text g, dim, @text
  end

end


class MackworthTestRunner

  attr_reader :show_lines
  attr_reader :current_line_length_in_mm

  def initialize mainpanel, iterations
    @mainpanel = mainpanel
    @iterations = iterations

    longiters = iterations * 0.25

    @key_timer = KeyList.new

    @mainpanel.add_key_listener @key_timer

    @show_lines = true
    update_line_length false

    @longindices = Set.new

    while @longindices.size < longiters
      @longindices << rand(iterations)
    end

    puts "@longindices: #{@longindices.inspect}"

    @responses = Array.new

    java.lang.Thread.new(self).start
  end

  def update_line_length is_long_len
    @current_line_length_in_mm = is_long_len ? MackworthTestParameters::LONG_LINE_LENGTH : MackworthTestParameters::SHORT_LINE_LENGTH
  end

  def repaint
    @mainpanel.repaint
  end

  def run_iteration num
    is_long = @longindices.include?(num)

    update_line_length is_long
    
    starttime = Time.now
    # puts "starting: #{starttime.to_f}"
    @key_timer.clear
    
    # puts "num: #{num}"

    @show_lines = true

    # $$$ looks like the JPanel intercepts the key event ...
    
    MackworthTestParameters::FLICKER_ITERATIONS.times do
      # puts "flickering: #{Time.new.to_f}"
      repaint
      java.lang.Thread.sleep(MackworthTestParameters::FLICKER_DURATION)
    end

    @show_lines = false
    
    # puts "pausing: #{Time.new.to_f}"

    repaint

    endtime = Time.now

    duration = endtime - starttime
    
    sleep_duration = (MackworthTestParameters::DISPLAY_DURATION - duration).to_i

    # puts "sleep_duration: #{sleep_duration}"

    if sleep_duration > 0
      java.lang.Thread.sleep sleep_duration
      # puts "done sleeping"
    end

    # puts "@key_timer: #{@key_timer}"

    # get it here, so subsequent calls don't let one "leak" in
    keytime = @key_timer.keytime
    
    # puts "keytime: #{keytime}"
    if keytime
      # puts "keytime: #{keytime.to_f}"
    end

    answered = !keytime.nil?

    response_time = answered ? keytime.to_f - starttime.to_f : -1.0

    # puts "response_time: #{response_time}"

    response = [ @user_id, response_time, answered, is_long, answered == is_long ]

    puts "response: #{response.inspect}"
    
    @responses << response

    # puts "done: #{Time.new.to_f}"
  end

  def run_test
    @show_lines = false

    @mainpanel.renderer = LineRenderer.new self

    java.lang.Thread.sleep 1000

    @iterations.times do |num|
      run_iteration num
    end
  end

  def show_outro
    @mainpanel.renderer = OutroRenderer.new self

    repaint
  end

  def run
    @user_id = Time.new.to_f
    
    puts "#{Time.new}: running"

    run_test

    show_outro
  end
end


class MackworthTest < MackworthTestRunner

  def initialize mainpanel
    super(mainpanel, MackworthTestParameters::ITERATIONS_PER_TEST)
  end

  def write_responses
    resfile = MackworthTestResultsFile.new

    resfile.addlines @responses

    resfile.write
  end

  def run
    super

    write_responses
  end
end


class MackworthTestDemo < MackworthTestRunner

  def initialize mainpanel
    super(mainpanel, 4)
  end

end


class MackworthTestIntro

  def initialize mainpanel
    @mainpanel = mainpanel

    java.lang.Thread.new(self).start
  end

  def run
    @mainpanel.renderer = IntroRenderer.new self
    @mainpanel.repaint

    java.lang.Thread.sleep MackworthTestParameters::INTRO_DURATION
  end
end


class MackworthTestFrame < JFrame

  def initialize
    super "Line Test"

    menubar = JMenuBar.new

    test_menu = JMenu.new "Test"
    test_menu.mnemonic = KeyEvent::VK_T

    item_new = JMenuItem.new "New"
    item_new.mnemonic = KeyEvent::VK_N
    item_new.tool_tip_text = "Run a new test"
    
    item_new.add_action_listener do |e|
      MackworthTest.new @panel
      
      @panel.grab_focus
    end

    test_menu.add item_new

    item_intro = JMenuItem.new "Intro"
    item_intro.mnemonic = KeyEvent::VK_I
    item_intro.tool_tip_text = "Run the intro"
    
    item_intro.add_action_listener do |e|
      puts "starting intro ..."
      MackworthTestIntro.new(@panel)
      puts "done creating intro ..."
      
      @panel.grab_focus
      puts "done grabbing focus"
    end

    test_menu.add item_intro

    item_demo = JMenuItem.new "Demo"
    item_demo.mnemonic = KeyEvent::VK_D
    item_demo.tool_tip_text = "Run the demo"
    
    item_demo.add_action_listener do |e|
      puts "starting demo ..."
      MackworthTestDemo.new(@panel)
      puts "done creating demo ..."
      
      @panel.grab_focus
      puts "done grabbing focus"
    end

    test_menu.add item_demo

    item_exit = JMenuItem.new "Exit"
    item_exit.add_action_listener do |e|
      dialog = javax.swing.JDialog.new

      ok = JOptionPane.show_confirm_dialog self, "Are you sure you want to quit?", "Quit?", JOptionPane::YES_NO_OPTION
      
      puts "ok? #{ok}"
      if ok == 0
        java.lang.System.exit 0
      else
        puts "not yet quitting!"
      end
    end
    
    item_exit.mnemonic = KeyEvent::VK_X
    item_exit.tool_tip_text = "Exit application"

    test_menu.add item_exit

    menubar.add test_menu

    help_menu = JMenu.new "Help"
    help_menu.mnemonic = KeyEvent::VK_H

    item_about = JMenuItem.new "About"
    item_about.mnemonic = KeyEvent::VK_A
    item_about.tool_tip_text = "Show information about the program"    

    item_about.add_action_listener do |e|
      JOptionPane.show_message_dialog self, "Written by Jeff Pace (jeugenepace at gmail dot com)", "About", JOptionPane::OK_OPTION
    end
      
    help_menu.add item_about

    menubar.add help_menu

    set_jmenu_bar menubar  

    # this works fine on Linux with Java 1.6, but not Windows with any version,
    # or Linux with Java 1.5:
    # set_extended_state JFrame::MAXIMIZED_BOTH
    # set_undecorated true
    
    set_default_close_operation JFrame::EXIT_ON_CLOSE
    set_location_relative_to nil
    get_content_pane.layout = java.awt.BorderLayout.new

    @panel = MainPanel.new

    get_content_pane.add @panel, java.awt.BorderLayout::CENTER

    @panel.layout = nil

    @panel.request_focus_in_window

    pack
    set_visible true

    move(0, 0)
    resize Toolkit.default_toolkit.screen_size
  end
end

class MackworthTestMain

  java_signature 'void main(String[])'
  def self.main args
    puts "starting main"

    MackworthTestFrame.new
  end
end


if __FILE__ == $0
  MackworthTestMain.main Array.new
end
