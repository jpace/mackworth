#!/usr/bin/jruby -w
# -*- ruby -*-

require 'csv'
require 'set'
require 'pathname'

require 'csvfile'
require 'drawer'
require 'panel'
require 'spacebarlistener'
require 'swingutil'

include Java

import java.awt.Color
import java.awt.RenderingHints
import java.awt.Toolkit
import java.awt.event.KeyEvent
import java.awt.event.KeyListener
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


# returns erratic, but not completely random, numbers
class ErraticNumberGenerator

  def initialize(upperlimit, max_span)
    @upperlimit = upperlimit
    @max_span   = max_span
    @previous   = @upperlimit / 2
  end

  def next
    lonum = nil
    hinum = nil

    if @previous < @max_span
      lonum = 0
      hinum = @max_span * 1.1
    elsif @previous + @max_span > @upperlimit
      lonum = @upperlimit - @max_span * 1.1
      hinum = @upperlimit
    else
      lonum = @previous - @max_span / 2
      hinum = @previous + @max_span / 2
    end

    nextnum = (lonum + rand(hinum - lonum)).to_i
    @previous = nextnum
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

module MackworthTestConstants

  APP_NAME = "Mackworth"
  
  SHORT_LINE_LENGTH  = [84,     84][$param_num] # mm
  LONG_LINE_FACTOR   = [1.15, 1.50][$param_num]
  LONG_LINE_LENGTH   = (SHORT_LINE_LENGTH * LONG_LINE_FACTOR).to_i
  LINE_RANDOM_LENGTH = 20

  DISPLAY_DURATION   = [1000, 3000][$param_num] # ms
  LINE_DURATION      = [300,  1000][$param_num] # ms
  FLICKER_DURATION   = 40                       # ms
  FLICKER_ITERATIONS = (LINE_DURATION.to_f / FLICKER_DURATION).to_i
  
  LINE_THICKNESS = 4
  DISTANCE_BETWEEN_LINES = 25

  FOREGROUND_COLOR = Color.new 50, 50, 50

  INTRO_DURATION = 5000         # ms

  # $$$ need confirmation about how many iterations to run here:
  ITERATIONS_PER_TEST = [10, 4][$param_num]
  
  # % of iterations to show long lines:
  LONGITERS   = ITERATIONS_PER_TEST * 0.25

  BACKGROUND_COLOR = Color.new 250, 250, 250

  BACKGROUND_COLOR_FLASH = Color.new 250, 0, 0
end


class MackworthLineDrawer < LineDrawer
  include MackworthTestConstants

  def initialize
    super(FOREGROUND_COLOR, LINE_THICKNESS)
  end
end


class LineRenderer < MackworthLineDrawer
  include MackworthTestConstants

  attr_accessor :length_in_mm

  def initialize test
    @test = test
    @dist_from_y = mm_to_pixels(DISTANCE_BETWEEN_LINES) / 2
    @eng = ErraticNumberGenerator.new(LINE_RANDOM_LENGTH, (LINE_RANDOM_LENGTH * 0.6).to_i)
    super()
  end

  def random_length base_len
    base_len + @eng.next - LINE_RANDOM_LENGTH / 2
  end

  def render g, dim
    return unless @test.show_lines

    g.color = FOREGROUND_COLOR
    
    length_in_mm = @test.current_line_length_in_mm
    ctr_y        = dim.height / 2

    [ -1, 1 ].each do |fact|
      draw_centered_line [ g, dim ], ctr_y + (fact * @dist_from_y), random_length(length_in_mm)
    end
  end

end


class TextRenderer < MackworthLineDrawer

  def render g, dim
    draw_text g, dim, text
  end

end


class IntroRenderer < MackworthLineDrawer

  def initialize
    super()
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

    draw_centered_line [ g, dim ], (ctr_y * 1.2).to_i, MackworthTestConstants::SHORT_LINE_LENGTH
    draw_centered_line [ g, dim ], (ctr_y * 1.4).to_i, MackworthTestConstants::LONG_LINE_LENGTH
  end

end


class OutroRenderer < MackworthLineDrawer

  attr_reader :text  

  def initialize
    @text = Array.new
    
    @text << "End of test."
    @text << ""

    super()
  end

end


class MackworthTestRunner

  attr_reader :show_lines
  attr_reader :current_line_length_in_mm

  def initialize mainpanel, iterations
    @mainpanel = mainpanel
    @iterations = iterations

    longiters = iterations * 0.25

    @key_timer = SpacebarKeyListener.new

    @mainpanel.add_key_listener @key_timer

    @show_lines = true
    update_line_length false

    @longindices = Set.new

    while @longindices.size < longiters
      @longindices << rand(iterations)
    end

    @responses = Array.new

    java.lang.Thread.new(self).start
  end

  def update_line_length is_long_len
    @current_line_length_in_mm = is_long_len ? MackworthTestConstants::LONG_LINE_LENGTH : MackworthTestConstants::SHORT_LINE_LENGTH
  end

  def repaint
    @mainpanel.repaint
  end

  def run_iteration num
    is_long = @longindices.include?(num)

    update_line_length is_long
    
    starttime = Time.now
    @key_timer.clear
    
    @show_lines = true

    MackworthTestConstants::FLICKER_ITERATIONS.times do
      repaint
      java.lang.Thread.sleep(MackworthTestConstants::FLICKER_DURATION)
    end

    @show_lines = false
    
    repaint

    endtime = Time.now

    duration = endtime - starttime
    
    sleep_duration = (MackworthTestConstants::DISPLAY_DURATION - duration).to_i

    if sleep_duration > 0
      java.lang.Thread.sleep sleep_duration
    end

    # get it here, so subsequent calls don't let one "leak" in
    keytime = @key_timer.keytime
    
    answered = !keytime.nil?

    response_time = answered ? keytime.to_f - starttime.to_f : -1.0

    is_correct = answered == is_long

    if !is_correct
      @mainpanel.background_color = MackworthTestConstants::BACKGROUND_COLOR_FLASH
      repaint
    end

    java.lang.Thread.sleep 250
    
    if !is_correct
      @mainpanel.background_color = MackworthTestConstants::BACKGROUND_COLOR
      repaint      
    end

    response = [ @user_id, response_time, answered, is_long, is_correct ]

    @responses << response
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
    @mainpanel.renderer = OutroRenderer.new

    repaint
  end

  def run
    @user_id = Time.new.to_f
    
    run_test

    show_outro
  end
end


class MackworthTest < MackworthTestRunner

  def initialize mainpanel
    super(mainpanel, MackworthTestConstants::ITERATIONS_PER_TEST)
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
    @mainpanel.renderer = IntroRenderer.new
    @mainpanel.repaint

    java.lang.Thread.sleep MackworthTestConstants::INTRO_DURATION
  end
end


class MackworthTestFrame < JFrame

  def initialize
    super MackworthTestConstants::APP_NAME

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
      MackworthTestIntro.new(@panel)
      @panel.grab_focus
    end

    test_menu.add item_intro

    item_demo = JMenuItem.new "Demo"
    item_demo.mnemonic = KeyEvent::VK_D
    item_demo.tool_tip_text = "Run the demo"
    
    item_demo.add_action_listener do |e|
      MackworthTestDemo.new(@panel)
      @panel.grab_focus
    end

    test_menu.add item_demo

    item_exit = JMenuItem.new "Exit"
    item_exit.add_action_listener do |e|
      dialog = javax.swing.JDialog.new

      ok = JOptionPane.show_confirm_dialog self, "Are you sure you want to quit?", "Quit?", JOptionPane::YES_NO_OPTION
      
      if ok == 0
        java.lang.System.exit 0
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
      appname = "Mackworth Psychological Vigilance Test"
      author  = "Jeff Pace (jeugenepace&#64;gmail&#46;com)"
      website = "http://www.incava.org"
      github  = "https://github.com/jeugenepace"
      msg     = "<html>"
      msg     << appname
      msg     << "<hr>"
      msg     << "Written by #{author}" << "<br>"
      msg     << "&nbsp;&nbsp;&nbsp #{website}" << "<br>"
      msg     << "&nbsp;&nbsp;&nbsp #{github}" << "<br>"
      msg     << "</html>"
      JOptionPane.show_message_dialog self, msg, "About", JOptionPane::OK_OPTION
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

    @panel = MainPanel.new(MackworthTestConstants::BACKGROUND_COLOR)

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
