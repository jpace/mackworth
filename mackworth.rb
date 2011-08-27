#!/usr/bin/jruby -w
# -*- ruby -*-

require 'set'
require 'pathname'

require 'csvfile'
require 'drawer'
require 'panel'
require 'spacebarlistener'
require 'swingutil'
require 'testframe'

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


class OutroRenderer < TextRenderer

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

  CSV_HEADER_FIELDS = [ "userid", "duration", "answered", "is_long", "accurate" ]

  CSV_FILE_NAME = 'mackworth.csv'

  def write_responses
    resfile = CSVFile.new CSV_FILE_NAME, CSV_HEADER_FIELDS
    
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


class MackworthTestFrame < TestFrame

  def initialize
    super(MackworthTestConstants::APP_NAME)
  end

  def run_test
    MackworthTest.new @panel
  end

  def run_intro
    MackworthTestIntro.new @panel
  end

  def run_demo
    MackworthTestDemo.new @panel
  end

  def get_about_text
    appname = "Mackworth Psychological Vigilance Test"
    author  = "Jeff Pace (jeugenepace&#64;gmail&#46;com)"
    website = "http://www.incava.org"
    github  = "https://github.com/jeugenepace"
    text    = "<html>"
    text    << appname
    text    << "<hr>"
    text    << "Written by #{author}" << "<br>"
    text    << "&nbsp;&nbsp;&nbsp #{website}" << "<br>"
    text    << "&nbsp;&nbsp;&nbsp #{github}" << "<br>"
    text    << "</html>"
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
