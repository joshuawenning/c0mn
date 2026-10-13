require "test_helper"
require "timeout"

class TagTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "concurrent creation resolves the same normalized tag" do
    name = "concurrent shared tag"
    Tag.where(name: name).destroy_all
    arrived = Queue.new
    proceed = Queue.new
    subscriber = ->(_event, _start, _finish, _id, payload) {
      if payload[:name] == "Tag Load" && Thread.current[:synchronize_tag_lookup]
        Thread.current[:synchronize_tag_lookup] = false
        arrived << true
        Timeout.timeout(10) { proceed.pop }
      end
    }

    tags = ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      threads = 2.times.map do
        Thread.new do
          Thread.current[:synchronize_tag_lookup] = true
          ActiveRecord::Base.connection_pool.with_connection { Tag.find_or_create_named!(name.upcase) }
        end
      end
      begin
        Timeout.timeout(10) { 2.times { arrived.pop } }
        2.times { proceed << true }
        Timeout.timeout(10) { threads.map(&:value) }
      ensure
        2.times { proceed << true }
        threads.each(&:join)
      end
    end

    assert_equal 1, tags.map(&:id).uniq.size
    assert_equal 1, Tag.where(name: name).count
  ensure
    Tag.where(name: name).destroy_all
  end
end
