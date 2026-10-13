module FormTestHelper
  def assert_invalid_field(name)
    assert_select "[role='alert']"
    fields = css_select("[name='#{name}'][aria-invalid='true'][aria-describedby]")
    assert_not_empty fields
    fields.each do |field|
      descriptions = field["aria-describedby"].split
      assert_not_empty descriptions
      descriptions.each { |id| assert_select "[id='#{id}']" }
    end
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include FormTestHelper
end
