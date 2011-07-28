class TestAccessibility < TestAX

  APP = AX::Application.new REF

  def close_button
    @@button ||= APP.attribute(:main_window).attribute(:children).find do |item|
      item.class == AX::CloseButton
    end
  end

end


class TestAccessibilityPath < TestAccessibility

  def setup
    @list = Accessibility.path(APP.main_window.close_button)
  end

  def test_returns_the_elements_in_a_list
    assert_instance_of Array, @list
    assert_kind_of     AX::Element, @list.first
  end

  def test_returns_correct_elements_in_order_from_highest_to_lowest
    assert_equal 3, @list.size
    assert_instance_of AX::CloseButton,    @list.first
    assert_instance_of AX::StandardWindow, @list.second
    assert_instance_of AX::Application,    @list.third
  end

end


class TestAccessibilityTree < TestAccessibility

  def test_tree_gives_me_a_tree
    assert_instance_of Accessibility::Tree, Accessibility.tree(APP)
  end

end


class TestAccessibilityElementUnderMouse < TestAccessibility

  def test_returns_some_kind_of_ax_element
    assert_kind_of AX::Element, Accessibility.element_under_mouse
  end

  def test_returns_element_under_the_mouse
    skip 'Need to move the mouse to a known location, then ask for the element'
  end

end


class TestAccessibilityElementAtPoint < TestAccessibility

  def test_returns_a_button_when_given_the_buttons_coordinates
    point = close_button.position
    assert_equal close_button, Accessibility.element_at_point(*point.to_a)
    assert_equal close_button, Accessibility.element_at_point(point.to_a)
    assert_equal close_button, Accessibility.element_at_point(point)
  end

  def test_also_responds_to_element_at_position
    assert_equal Accessibility.method(:element_at_point), Accessibility.method(:element_at_position)
  end

end


class TestAccessibilityApplicationWithBundleIdentifier < TestAccessibility

  def test_makes_an_app
    ret = Accessibility.application_with_bundle_identifier(APP_BUNDLE_IDENTIFIER)
    assert_instance_of AX::Application, ret
  end

  def test_gets_app_when_app_is_already_running
    app = Accessibility.application_with_bundle_identifier 'com.apple.dock'
    assert_instance_of AX::Application, app
    assert_equal 'Dock', app.attribute(:title)
  end

  # @todo how do we test when app is not already running?

  def test_launches_app_if_it_is_not_running
    skip 'Another difficult test to implement'
  end

  def test_times_out_if_app_cannot_be_launched
    skip 'This is difficult to do...'
  end

  def test_allows_override_of_the_sleep_time
    skip 'This is difficult to test...'
  end

end


class TestAccessibilityApplicationWithName < TestAccessibility

  def test_application_with_name_with_proper_app
    ret = Accessibility.application_with_name 'Dock'
    assert_instance_of AX::Application, ret
    assert_equal       'Dock', ret.title
  end

  def test_application_with_name_with_non_existant_app
    assert_nil Accessibility.application_with_name('App That Does Not Exist')
  end

end


class TestAccessibilityApplicationWithPID < TestAccessibility

  def test_gives_me_an_application
    pid = APP.pid
    app = Accessibility.application_with_pid(pid)
    assert_equal APP, app
  end

  def test_bad_pid
    skip 'A bad PID will cause MacRuby to explode'
    assert_nil Accessibility.application_with_pid(0)
  end

end