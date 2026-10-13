class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later.", status: :see_other }

  def new
  end

  def create
    credentials = params.permit(:email_address, :password)
    email_address = credentials[:email_address].to_s
    password = credentials[:password] if credentials[:password].is_a?(String)

    if user = User.authenticate_by(email_address: email_address, password: password)
      return_to = after_authentication_url
      reset_session
      start_new_session_for user
      redirect_to return_to, status: :see_other
    else
      redirect_to new_session_path, alert: "Try another email address or password.", status: :see_other
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
