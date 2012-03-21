class TestAccessibilityStringLexer < MiniTest::Unit::TestCase

  def lexer
    Accessibility::String::Lexer
  end

  def test_lex_method_chaining
    l = lexer.new ''
    assert_kind_of lexer, l.lex
  end

  def test_lex_single_custom
    l = lexer.new('\CMD').lex
    assert_equal [['\CMD']], l.tokens
  end

  def test_lex_hotkey_custom
    l = lexer.new('\COMMAND+,').lex
    assert_equal [['\COMMAND',[',']]], l.tokens
  end

  def test_lex_multiple_custom
    l = lexer.new('\COMMAND+\SHIFT+s').lex
    assert_equal [['\COMMAND',['\SHIFT',['s']]]], l.tokens
  end

  def test_lex_simple_string
    l = lexer.new('"It Just Works"™').lex
    assert_equal ['"','I','t',' ','J','u','s','t',' ','W','o','r','k','s','"','™'], l.tokens

    l = lexer.new('Martini, shaken.').lex
    assert_equal ['M','a','r','t','i','n','i',',',' ','s','h','a','k','e','n','.'], l.tokens

    l = lexer.new('Aston Martin DB7').lex
    assert_equal ['A','s','t','o','n',' ','M','a','r','t','i','n',' ','D','B','7'], l.tokens
  end

  def test_lex_ruby_escapes
    l = lexer.new("The cake is a lie\b\b\bdelicious").lex
    assert_equal ['T','h','e',' ','c','a','k','e',' ','i','s',' ','a',' ','l','i','e',"\b","\b","\b",'d','e','l','i','c','i','o','u','s'], l.tokens
  end

  def test_lex_complex_string
    l = lexer.new("\\COMMAND+a \bI deleted your text, lol!").lex
    assert_equal [['\COMMAND',['a']],"\b",'I',' ','d','e','l','e','t','e','d',' ','y','o','u','r',' ','t','e','x','t',',',' ','l','o','l','!'], l.tokens
  end

  def test_lex_backslash
    l = lexer.new("\\").lex
    assert_equal ["\\"], l.tokens

    l = lexer.new('\ ').lex
    assert_equal ["\\",' '], l.tokens

    l = lexer.new('\hmm').lex
    assert_equal ["\\",'h','m','m'], l.tokens

    # is this the job of the parser or the lexer?
    l = lexer.new('\HMM').lex
    assert_equal [["\\HMM"]], l.tokens
  end

  def test_lex_bad_custom_seq
    l = lexer.new('\COMMAND+').lex
    assert_equal [['\COMMAND',['']]], l.tokens
  end

  def test_lex_is_idempotent
    l = lexer.new('hey')
    tokens       = l.lex.tokens.dup
    other_tokens = l.lex.tokens
    assert_equal tokens, other_tokens
  end

end


class TestAccessibilityStringEventGenerator < MiniTest::Unit::TestCase

  def generator
    Accessibility::String::EventGenerator
  end

  def generate *tokens
    generator.new(tokens).generate.events
  end

  # key code for the left shift key
  def shift_down; [56,true];  end
  def shift_up;   [56,false]; end

  # key code for the left option key
  def option_down; [58,true];  end
  def option_up;   [58,false]; end

  def map
    @@map ||= KeyCoder.dynamic_mapping
  end

  def test_generate_lowercase
    c, a, k, e = map.values_at 'c', 'a', 'k', 'e'
    expected = [[c,true],[c,false],
                [a,true],[a,false],
                [k,true],[k,false],
                [e,true],[e,false]]
    actual   = generate 'c', 'a', 'k', 'e'
    assert_equal expected, actual
  end

  def test_generate_uppercase
    h, i = map.values_at 'h', 'i'
    expected = [shift_down,[h,true],[h,false],shift_up,
                shift_down,[i,true],[i,false],shift_up]
    actual   = generate 'H', 'I'
    assert_equal expected, actual
  end

  def test_generate_numbers
    two, four = map.values_at '2', '4'
    expected  = [[four,true],[four,false],[two,true],[two,false]]
    actual    = generate '4', '2'
    assert_equal expected, actual
  end

  def test_generate_ruby_escapes
    retern, tab, space = map.values_at "\r", "\t", "\s"

    expected = [[retern,true],[retern,false]]
    actual   = generate "\r"
    assert_equal expected, actual

    expected = expected
    actual   = generate "\n"
    assert_equal expected, actual

    expected = [[tab,true],[tab,false]]
    actual   = generate "\t"
    assert_equal expected, actual

    expected = [[space,true],[space,false]]
    actual   = generate "\s"
    assert_equal expected, actual

    expected = expected
    actual   = generate ' '
    assert_equal expected, actual
  end

  def test_generate_symbols
    dash, comma, apostrophe, bang, at, paren, chev =
     map.values_at '-', ',', "'", '1', '2', '9', '.'

    expected = [[dash,true],[dash,false]]
    actual   = generate '-'
    assert_equal expected, actual

    expected = [[comma,true],[comma,false]]
    actual   = generate ","
    assert_equal expected, actual

    expected = [[apostrophe,true],[apostrophe,false]]
    actual   = generate "'"
    assert_equal expected, actual

    expected = [shift_down,[bang,true],[bang,false],shift_up]
    actual   = generate '!'
    assert_equal expected, actual

    expected = [shift_down,[at,true],[at,false],shift_up]
    actual   = generate '@'
    assert_equal expected, actual

    expected = [shift_down,[paren,true],[paren,false],shift_up]
    actual   = generate '('
    assert_equal expected, actual

    expected = [shift_down,[chev,true],[chev,false],shift_up]
    actual   = generate '>'
    assert_equal expected, actual
  end

  def test_generate_unicode # holding option
    sigma, tm, gbp, omega = map.values_at 'w', '2', '3', 'z'

    expected = [option_down, [sigma,true],[sigma,false], option_up]
    actual   = generate '∑'
    assert_equal expected, actual

    expected = [option_down, [tm,true],[tm,false], option_up]
    actual   = generate '™'
    assert_equal expected, actual

    expected = [option_down, [gbp,true],[gbp,false], option_up]
    actual   = generate '£'
    assert_equal expected, actual

    expected = [option_down, [omega,true],[omega,false], option_up]
    actual   = generate 'Ω'
    assert_equal expected, actual
  end

  def test_generate_backslashes
    backslash, space, h, m =
      map.values_at "\\", ' ', 'h', 'm'

    expected = [[backslash,true],[backslash,false]]
    actual   = generate "\\"
    assert_equal expected, actual

    expected = [[backslash,true],[backslash,false],
                [space,true],[space,false]]
    actual   = generate "\\",' '
    assert_equal expected, actual

    expected = [[backslash,true],[backslash,false],
                [h,true],[h,false],
                [m,true],[m,false],
                [m,true],[m,false]]
    actual   = generate "\\",'h','m','m'
    assert_equal expected, actual

    # is this the job of the parser or the lexer?
    expected = [[backslash,true],[backslash,false],
                shift_down,[h,true],[h,false],shift_up,
                shift_down,[m,true],[m,false],shift_up,
                shift_down,[m,true],[m,false],shift_up]
    actual   = generate ["\\HMM"]
    assert_equal expected, actual
  end

  def test_generate_a_custom_escape
    command  = 0x37
    expected = [[command,true],[command,false]]
    actual   = generate ['\COMMAND']
    assert_equal expected, actual
  end

  def test_generate_hotkey
    right_arrow = 0x7c
    command     = 0x37
    expected = [[command,true],
                  shift_down,
                    [right_arrow,true],
                    [right_arrow,false],
                  shift_up,
                [command,false]]
    actual   = generate ['\COMMAND',['\SHIFT',['\->']]]
    assert_equal expected, actual
  end

  def test_generate_after_hotkey
    ctrl, a, space, h, i = 0x3B, *map.values_at('a',' ','h','i')
    expected = [[ctrl,true],
                 [a,true],[a,false],
                [ctrl,false],
                [space,true],[space,false],
                [h,true],[h,false],[i,true],[i,false]
               ]
    actual   = generate ['\CTRL',['a']], ' ', 'h', 'i'
    assert_equal expected, actual
  end

  def test_bails_for_unmapped_token
    assert_raises ArgumentError do
      generate '☃'
    end
  end

  def test_generation_is_idempotent
    g = generator.new(['M'])
    original_events = g.generate.events.dup
    new_events      = g.generate.events
    assert_equal original_events, new_events
  end

end


class TestAccessibilityString < MiniTest::Unit::TestCase
  include Accessibility::String

  # hmmmmm....
  def test_events_for_regular_case
    events = keyboard_events_for 'cheezburger'
    assert_kind_of Array, events
    refute_empty events

    assert_kind_of Array, events.first
    assert_kind_of Array, events.second
  end

  def test_dynamic_map_initialized
    refute_empty Accessibility::String::EventGenerator::MAPPING
  end

  def test_alias_is_included
    map = Accessibility::String::EventGenerator::MAPPING
    assert_equal map["\r"], map["\n"]
  end

  def test_can_parse_empty_string
    assert_equal [], keyboard_events_for('')
  end

end
