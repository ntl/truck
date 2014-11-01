require 'test_helper'

class DefineContextTest < Minitest::Test
  def test_must_supply_required_options
    error = assert_raises ArgumentError do
      Truck.define_context "hey"
    end

    assert_equal "missing keyword: root", error.message
  end
end
