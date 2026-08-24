class ErrorsController < ApplicationController
  allow_unauthenticated_access

  def show
    status = request.path_parameters[:status].to_i

    if status == 404
      render :not_found, status: status
    else
      render file: Rails.public_path.join("errors/#{status}.html"), layout: false, status: status, content_type: "text/html"
    end
  end
end
