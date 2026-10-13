class ErrorsController < ApplicationController
  allow_unauthenticated_access

  def show
    status = request.path_parameters[:status].to_i

    if status == 404
      render :not_found, status: status
    else
      file = status == 400 ? "400.html" : "errors/#{status}.html"
      render file: Rails.public_path.join(file), layout: false, status: status, content_type: "text/html"
    end
  end
end
