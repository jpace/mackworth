

import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.RubyClass;


public class ErraticNumberGenerator extends RubyObject  {
    private static final Ruby __ruby__ = Ruby.getGlobalRuntime();
    private static final RubyClass __metaclass__;

    static {
        String source = new StringBuilder("#!/usr/bin/jruby -w\n" +
            "# -*- ruby -*-\n" +
            "\n" +
            "require 'csv'\n" +
            "require 'set'\n" +
            "require 'pathname'\n" +
            "\n" +
            "require 'csvfile'\n" +
            "require 'drawer'\n" +
            "require 'panel'\n" +
            "require 'spacebarlistener'\n" +
            "require 'swingutil'\n" +
            "\n" +
            "include Java\n" +
            "\n" +
            "import java.awt.Color\n" +
            "import java.awt.RenderingHints\n" +
            "import java.awt.Toolkit\n" +
            "import java.awt.event.KeyEvent\n" +
            "import java.awt.event.KeyListener\n" +
            "import java.awt.geom.Ellipse2D\n" +
            "import javax.swing.JButton\n" +
            "import javax.swing.JFrame\n" +
            "import javax.swing.JMenu\n" +
            "import javax.swing.JMenuBar\n" +
            "import javax.swing.JMenuItem\n" +
            "import javax.swing.JOptionPane\n" +
            "import javax.swing.JPanel\n" +
            "\n" +
            "# Log.level = Log::DEBUG\n" +
            "\n" +
            "$testing = false\n" +
            "$param_num = $testing ? 1 : 0   # 0 == actual; 1 == testing\n" +
            "\n" +
            "\n" +
            "# returns erratic, but not completely random, numbers\n" +
            "class ErraticNumberGenerator\n" +
            "\n" +
            "  def initialize(upperlimit, max_span)\n" +
            "    @upperlimit = upperlimit\n" +
            "    @max_span   = max_span\n" +
            "    @previous   = @upperlimit / 2\n" +
            "  end\n" +
            "\n" +
            "  def next\n" +
            "    lonum = nil\n" +
            "    hinum = nil\n" +
            "\n" +
            "    if @previous < @max_span\n" +
            "      lonum = 0\n" +
            "      hinum = @max_span * 1.1\n" +
            "    elsif @previous + @max_span > @upperlimit\n" +
            "      lonum = @upperlimit - @max_span * 1.1\n" +
            "      hinum = @upperlimit\n" +
            "    else\n" +
            "      lonum = @previous - @max_span / 2\n" +
            "      hinum = @previous + @max_span / 2\n" +
            "    end\n" +
            "\n" +
            "    nextnum = (lonum + rand(hinum - lonum)).to_i\n" +
            "    @previous = nextnum\n" +
            "  end\n" +
            "\n" +
            "end\n" +
            "\n" +
            "\n" +
            "\n" +
            "class MackworthTestResultsFile \n" +
            "\n" +
            "  CSV_HEADER_FIELDS = [ \"userid\", \"duration\", \"answered\", \"is_long\", \"accurate\" ]\n" +
            "\n" +
            "  CSV_FILE_NAME = 'mackworth.csv'\n" +
            "\n" +
            "  def self.home_directory\n" +
            "    home = ENV['HOME']\n" +
            "    unless home\n" +
            "      home = (ENV['HOMEDRIVE'] || \"\") + (ENV['HOMEPATH'] || \"\")\n" +
            "    end\n" +
            "    \n" +
            "    homedir = ENV['HOME'] || (ENV['HOMEDRIVE'] + ENV['HOMEPATH'])\n" +
            "    Pathname.new(homedir)\n" +
            "  end\n" +
            "\n" +
            "  def initialize\n" +
            "    @csv_file = self.class.home_directory + CSV_FILE_NAME\n" +
            "    \n" +
            "    @csv_lines = @csv_file.exist? ? CSV.read(@csv_file.to_s) : [ CSV_HEADER_FIELDS ]\n" +
            "  end\n" +
            "\n" +
            "  def addlines lines\n" +
            "    @csv_lines.concat lines\n" +
            "  end\n" +
            "\n" +
            "  def write\n" +
            "    @csv_lines.each do |line|\n" +
            "      puts line\n" +
            "    end\n" +
            "\n" +
            "    CSV.open @csv_file.to_s, 'w' do |csv|\n" +
            "      @csv_lines.each do |line|\n" +
            "        csv << line\n" +
            "      end\n" +
            "    end\n" +
            "  end\n" +
            "end\n" +
            "\n" +
            "module MackworthTestConstants\n" +
            "\n" +
            "  APP_NAME = \"Mackworth\"\n" +
            "  \n" +
            "  SHORT_LINE_LENGTH  = [84,     84][$param_num] # mm\n" +
            "  LONG_LINE_FACTOR   = [1.15, 1.50][$param_num]\n" +
            "  LONG_LINE_LENGTH   = (SHORT_LINE_LENGTH * LONG_LINE_FACTOR).to_i\n" +
            "  LINE_RANDOM_LENGTH = 20\n" +
            "\n" +
            "  DISPLAY_DURATION   = [1000, 3000][$param_num] # ms\n" +
            "  LINE_DURATION      = [300,  1000][$param_num] # ms\n" +
            "  FLICKER_DURATION   = 40                       # ms\n" +
            "  FLICKER_ITERATIONS = (LINE_DURATION.to_f / FLICKER_DURATION).to_i\n" +
            "  \n" +
            "  LINE_THICKNESS = 4\n" +
            "  DISTANCE_BETWEEN_LINES = 25\n" +
            "\n" +
            "  FOREGROUND_COLOR = Color.new 50, 50, 50\n" +
            "\n" +
            "  INTRO_DURATION = 5000         # ms\n" +
            "\n" +
            "  # $$$ need confirmation about how many iterations to run here:\n" +
            "  ITERATIONS_PER_TEST = [10, 4][$param_num]\n" +
            "  \n" +
            "  # % of iterations to show long lines:\n" +
            "  LONGITERS   = ITERATIONS_PER_TEST * 0.25\n" +
            "\n" +
            "  BACKGROUND_COLOR = Color.new 250, 250, 250\n" +
            "\n" +
            "  BACKGROUND_COLOR_FLASH = Color.new 250, 0, 0\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class MackworthLineDrawer < LineDrawer\n" +
            "  include MackworthTestConstants\n" +
            "\n" +
            "  def initialize\n" +
            "    super(FOREGROUND_COLOR, LINE_THICKNESS)\n" +
            "  end\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class LineRenderer < MackworthLineDrawer\n" +
            "  include MackworthTestConstants\n" +
            "\n" +
            "  attr_accessor :length_in_mm\n" +
            "\n" +
            "  def initialize test\n" +
            "    @test = test\n" +
            "    @dist_from_y = mm_to_pixels(DISTANCE_BETWEEN_LINES) / 2\n" +
            "    @eng = ErraticNumberGenerator.new(LINE_RANDOM_LENGTH, (LINE_RANDOM_LENGTH * 0.6).to_i)\n" +
            "    super()\n" +
            "  end\n" +
            "\n" +
            "  def random_length base_len\n" +
            "    base_len + @eng.next - LINE_RANDOM_LENGTH / 2\n" +
            "  end\n" +
            "\n" +
            "  def render g, dim\n" +
            "    return unless @test.show_lines\n" +
            "\n" +
            "    g.color = FOREGROUND_COLOR\n" +
            "    \n" +
            "    length_in_mm = @test.current_line_length_in_mm\n" +
            "    ctr_y        = dim.height / 2\n" +
            "\n" +
            "    [ -1, 1 ].each do |fact|\n" +
            "      draw_centered_line [ g, dim ], ctr_y + (fact * @dist_from_y), random_length(length_in_mm)\n" +
            "    end\n" +
            "  end\n" +
            "\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class TextRenderer < MackworthLineDrawer\n" +
            "\n" +
            "  def render g, dim\n" +
            "    draw_text g, dim, text\n" +
            "  end\n" +
            "\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class IntroRenderer < MackworthLineDrawer\n" +
            "\n" +
            "  def initialize\n" +
            "    super()\n" +
            "    @text = Array.new\n" +
            "    \n" +
            "    @text << \"For each of the following screens,\"\n" +
            "    @text << \"press the spacebar when you see the longer\"\n" +
            "    @text << \"pair of lines.\"\n" +
            "    @text << \"\"\n" +
            "    @text << \"Below are the shorter and longer lines.\"\n" +
            "  end\n" +
            "\n" +
            "  def render g, dim\n" +
            "    draw_text g, dim, @text\n" +
            "\n" +
            "    ctr_y = dim.height / 2\n" +
            "\n" +
            "    draw_centered_line [ g, dim ], (ctr_y * 1.2).to_i, MackworthTestConstants::SHORT_LINE_LENGTH\n" +
            "    draw_centered_line [ g, dim ], (ctr_y * 1.4).to_i, MackworthTestConstants::LONG_LINE_LENGTH\n" +
            "  end\n" +
            "\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class OutroRenderer < MackworthLineDrawer\n" +
            "\n" +
            "  attr_reader :text  \n" +
            "\n" +
            "  def initialize\n" +
            "    @text = Array.new\n" +
            "    \n" +
            "    @text << \"End of test.\"\n" +
            "    @text << \"\"\n" +
            "\n" +
            "    super()\n" +
            "  end\n" +
            "\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class MackworthTestRunner\n" +
            "\n" +
            "  attr_reader :show_lines\n" +
            "  attr_reader :current_line_length_in_mm\n" +
            "\n" +
            "  def initialize mainpanel, iterations\n" +
            "    @mainpanel = mainpanel\n" +
            "    @iterations = iterations\n" +
            "\n" +
            "    longiters = iterations * 0.25\n" +
            "\n" +
            "    @key_timer = SpacebarKeyListener.new\n" +
            "\n" +
            "    @mainpanel.add_key_listener @key_timer\n" +
            "\n" +
            "    @show_lines = true\n" +
            "    update_line_length false\n" +
            "\n" +
            "    @longindices = Set.new\n" +
            "\n" +
            "    while @longindices.size < longiters\n" +
            "      @longindices << rand(iterations)\n" +
            "    end\n" +
            "\n" +
            "    @responses = Array.new\n" +
            "\n" +
            "    java.lang.Thread.new(self).start\n" +
            "  end\n" +
            "\n" +
            "  def update_line_length is_long_len\n" +
            "    @current_line_length_in_mm = is_long_len ? MackworthTestConstants::LONG_LINE_LENGTH : MackworthTestConstants::SHORT_LINE_LENGTH\n" +
            "  end\n" +
            "\n" +
            "  def repaint\n" +
            "    @mainpanel.repaint\n" +
            "  end\n" +
            "\n" +
            "  def run_iteration num\n" +
            "    is_long = @longindices.include?(num)\n" +
            "\n" +
            "    update_line_length is_long\n" +
            "    \n" +
            "    starttime = Time.now\n" +
            "    @key_timer.clear\n" +
            "    \n" +
            "    @show_lines = true\n" +
            "\n" +
            "    MackworthTestConstants::FLICKER_ITERATIONS.times do\n" +
            "      repaint\n" +
            "      java.lang.Thread.sleep(MackworthTestConstants::FLICKER_DURATION)\n" +
            "    end\n" +
            "\n" +
            "    @show_lines = false\n" +
            "    \n" +
            "    repaint\n" +
            "\n" +
            "    endtime = Time.now\n" +
            "\n" +
            "    duration = endtime - starttime\n" +
            "    \n" +
            "    sleep_duration = (MackworthTestConstants::DISPLAY_DURATION - duration).to_i\n" +
            "\n" +
            "    if sleep_duration > 0\n" +
            "      java.lang.Thread.sleep sleep_duration\n" +
            "    end\n" +
            "\n" +
            "    # get it here, so subsequent calls don't let one \"leak\" in\n" +
            "    keytime = @key_timer.keytime\n" +
            "    \n" +
            "    answered = !keytime.nil?\n" +
            "\n" +
            "    response_time = answered ? keytime.to_f - starttime.to_f : -1.0\n" +
            "\n" +
            "    is_correct = answered == is_long\n" +
            "\n" +
            "    if !is_correct\n" +
            "      @mainpanel.background_color = MackworthTestConstants::BACKGROUND_COLOR_FLASH\n" +
            "      repaint\n" +
            "    end\n" +
            "\n" +
            "    java.lang.Thread.sleep 250\n" +
            "    \n" +
            "    if !is_correct\n" +
            "      @mainpanel.background_color = MackworthTestConstants::BACKGROUND_COLOR\n" +
            "      repaint      \n" +
            "    end\n" +
            "\n" +
            "    response = [ @user_id, response_time, answered, is_long, is_correct ]\n" +
            "\n" +
            "    @responses << response\n" +
            "  end\n" +
            "\n" +
            "  def run_test\n" +
            "    @show_lines = false\n" +
            "\n" +
            "    @mainpanel.renderer = LineRenderer.new self\n" +
            "\n" +
            "    java.lang.Thread.sleep 1000\n" +
            "\n" +
            "    @iterations.times do |num|\n" +
            "      run_iteration num\n" +
            "    end\n" +
            "  end\n" +
            "\n" +
            "  def show_outro\n" +
            "    @mainpanel.renderer = OutroRenderer.new\n" +
            "\n" +
            "    repaint\n" +
            "  end\n" +
            "\n" +
            "  def run\n" +
            "    @user_id = Time.new.to_f\n" +
            "    \n" +
            "    run_test\n" +
            "\n" +
            "    show_outro\n" +
            "  end\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class MackworthTest < MackworthTestRunner\n" +
            "\n" +
            "  def initialize mainpanel\n" +
            "    super(mainpanel, MackworthTestConstants::ITERATIONS_PER_TEST)\n" +
            "  end\n" +
            "\n" +
            "  def write_responses\n" +
            "    resfile = MackworthTestResultsFile.new\n" +
            "\n" +
            "    resfile.addlines @responses\n" +
            "\n" +
            "    resfile.write\n" +
            "  end\n" +
            "\n" +
            "  def run\n" +
            "    super\n" +
            "\n" +
            "    write_responses\n" +
            "  end\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class MackworthTestDemo < MackworthTestRunner\n" +
            "\n" +
            "  def initialize mainpanel\n" +
            "    super(mainpanel, 4)\n" +
            "  end\n" +
            "\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class MackworthTestIntro\n" +
            "\n" +
            "  def initialize mainpanel\n" +
            "    @mainpanel = mainpanel\n" +
            "\n" +
            "    java.lang.Thread.new(self).start\n" +
            "  end\n" +
            "\n" +
            "  def run\n" +
            "    @mainpanel.renderer = IntroRenderer.new\n" +
            "    @mainpanel.repaint\n" +
            "\n" +
            "    java.lang.Thread.sleep MackworthTestConstants::INTRO_DURATION\n" +
            "  end\n" +
            "end\n" +
            "\n" +
            "\n" +
            "class MackworthTestFrame < JFrame\n" +
            "\n" +
            "  def initialize\n" +
            "    super MackworthTestConstants::APP_NAME\n" +
            "\n" +
            "    menubar = JMenuBar.new\n" +
            "\n" +
            "    test_menu = JMenu.new \"Test\"\n" +
            "    test_menu.mnemonic = KeyEvent::VK_T\n" +
            "\n" +
            "    item_new = JMenuItem.new \"New\"\n" +
            "    item_new.mnemonic = KeyEvent::VK_N\n" +
            "    item_new.tool_tip_text = \"Run a new test\"\n" +
            "    \n" +
            "    item_new.add_action_listener do |e|\n" +
            "      MackworthTest.new @panel\n" +
            "      @panel.grab_focus\n" +
            "    end\n" +
            "\n" +
            "    test_menu.add item_new\n" +
            "\n" +
            "    item_intro = JMenuItem.new \"Intro\"\n" +
            "    item_intro.mnemonic = KeyEvent::VK_I\n" +
            "    item_intro.tool_tip_text = \"Run the intro\"\n" +
            "    \n" +
            "    item_intro.add_action_listener do |e|\n" +
            "      MackworthTestIntro.new(@panel)\n" +
            "      @panel.grab_focus\n" +
            "    end\n" +
            "\n" +
            "    test_menu.add item_intro\n" +
            "\n" +
            "    item_demo = JMenuItem.new \"Demo\"\n" +
            "    item_demo.mnemonic = KeyEvent::VK_D\n" +
            "    item_demo.tool_tip_text = \"Run the demo\"\n" +
            "    \n" +
            "    item_demo.add_action_listener do |e|\n" +
            "      MackworthTestDemo.new(@panel)\n" +
            "      @panel.grab_focus\n" +
            "    end\n" +
            "\n" +
            "    test_menu.add item_demo\n" +
            "\n" +
            "    item_exit = JMenuItem.new \"Exit\"\n" +
            "    item_exit.add_action_listener do |e|\n" +
            "      dialog = javax.swing.JDialog.new\n" +
            "\n" +
            "      ok = JOptionPane.show_confirm_dialog self, \"Are you sure you want to quit?\", \"Quit?\", JOptionPane::YES_NO_OPTION\n" +
            "      \n" +
            "      if ok == 0\n" +
            "        java.lang.System.exit 0\n" +
            "      end\n" +
            "    end\n" +
            "    \n" +
            "    item_exit.mnemonic = KeyEvent::VK_X\n" +
            "    item_exit.tool_tip_text = \"Exit application\"\n" +
            "\n" +
            "    test_menu.add item_exit\n" +
            "\n" +
            "    menubar.add test_menu\n" +
            "\n" +
            "    help_menu = JMenu.new \"Help\"\n" +
            "    help_menu.mnemonic = KeyEvent::VK_H\n" +
            "\n" +
            "    item_about = JMenuItem.new \"About\"\n" +
            "    item_about.mnemonic = KeyEvent::VK_A\n" +
            "    item_about.tool_tip_text = \"Show information about the program\"    \n" +
            "\n" +
            "    item_about.add_action_listener do |e|\n" +
            "      appname = \"Mackworth Psychological Vigilance Test\"\n" +
            "      author  = \"Jeff Pace (jeugenepace&#64;gmail&#46;com)\"\n" +
            "      website = \"http://www.incava.org\"\n" +
            "      github  = \"https://github.com/jeugenepace\"\n" +
            "      msg     = \"<html>\"\n" +
            "      msg     << appname\n" +
            "      msg     << \"<hr>\"\n" +
            "      msg     << \"Written by #{author}\" << \"<br>\"\n" +
            "      msg     << \"&nbsp;&nbsp;&nbsp #{website}\" << \"<br>\"\n" +
            "      msg     << \"&nbsp;&nbsp;&nbsp #{github}\" << \"<br>\"\n" +
            "      msg     << \"</html>\"\n" +
            "      JOptionPane.show_message_dialog self, msg, \"About\", JOptionPane::OK_OPTION\n" +
            "    end\n" +
            "      \n" +
            "    help_menu.add item_about\n" +
            "\n" +
            "    menubar.add help_menu\n" +
            "\n" +
            "    set_jmenu_bar menubar  \n" +
            "\n" +
            "    # this works fine on Linux with Java 1.6, but not Windows with any version,\n" +
            "    # or Linux with Java 1.5:\n" +
            "    # set_extended_state JFrame::MAXIMIZED_BOTH\n" +
            "    # set_undecorated true\n" +
            "    \n" +
            "    set_default_close_operation JFrame::EXIT_ON_CLOSE\n" +
            "    set_location_relative_to nil\n" +
            "    get_content_pane.layout = java.awt.BorderLayout.new\n" +
            "\n" +
            "    @panel = MainPanel.new(MackworthTestConstants::BACKGROUND_COLOR)\n" +
            "\n" +
            "    get_content_pane.add @panel, java.awt.BorderLayout::CENTER\n" +
            "\n" +
            "    @panel.layout = nil\n" +
            "\n" +
            "    @panel.request_focus_in_window\n" +
            "\n" +
            "    pack\n" +
            "    set_visible true\n" +
            "\n" +
            "    move(0, 0)\n" +
            "    resize Toolkit.default_toolkit.screen_size\n" +
            "  end\n" +
            "end\n" +
            "\n" +
            "class MackworthTestMain\n" +
            "\n" +
            "  java_signature 'void main(String[])'\n" +
            "  def self.main args\n" +
            "    puts \"starting main\"\n" +
            "\n" +
            "    MackworthTestFrame.new\n" +
            "  end\n" +
            "end\n" +
            "\n" +
            "\n" +
            "if __FILE__ == $0\n" +
            "  MackworthTestMain.main Array.new\n" +
            "end\n" +
            "").toString();
        __ruby__.executeScript(source, "mackworth.rb");
        RubyClass metaclass = __ruby__.getClass("ErraticNumberGenerator");
        metaclass.setRubyStaticAllocator(ErraticNumberGenerator.class);
        if (metaclass == null) throw new NoClassDefFoundError("Could not load Ruby class: ErraticNumberGenerator");
        __metaclass__ = metaclass;
    }

    /**
     * Standard Ruby object constructor, for construction-from-Ruby purposes.
     * Generally not for user consumption.
     *
     * @param ruby The JRuby instance this object will belong to
     * @param metaclass The RubyClass representing the Ruby class of this object
     */
    private ErraticNumberGenerator(Ruby ruby, RubyClass metaclass) {
        super(ruby, metaclass);
    }

    /**
     * A static method used by JRuby for allocating instances of this object
     * from Ruby. Generally not for user comsumption.
     *
     * @param ruby The JRuby instance this object will belong to
     * @param metaclass The RubyClass representing the Ruby class of this object
     */
    public static IRubyObject __allocate__(Ruby ruby, RubyClass metaClass) {
        return new ErraticNumberGenerator(ruby, metaClass);
    }

    
    public  ErraticNumberGenerator(Object upperlimit, Object max_span) {
        this(__ruby__, __metaclass__);
        IRubyObject ruby_upperlimit = JavaUtil.convertJavaToRuby(__ruby__, upperlimit);
        IRubyObject ruby_max_span = JavaUtil.convertJavaToRuby(__ruby__, max_span);
        RuntimeHelpers.invoke(__ruby__.getCurrentContext(), this, "initialize", ruby_upperlimit, ruby_max_span);

    }

    
    public Object next() {

        IRubyObject ruby_result = RuntimeHelpers.invoke(__ruby__.getCurrentContext(), this, "next");
        return (Object)ruby_result.toJava(Object.class);

    }

}
