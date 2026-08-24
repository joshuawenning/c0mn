module Admin
  class BaseController < ApplicationController
    before_action :require_platform_admin

    private

    def require_platform_admin
      head :forbidden unless Current.user.platform_admin?
    end
  end
end
