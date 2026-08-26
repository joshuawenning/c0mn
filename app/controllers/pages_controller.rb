class PagesController < ApplicationController
  allow_unauthenticated_access

  def about
    @status_checked_at = Time.current
  end
end
