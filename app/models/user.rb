class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :username, with: ->(username) { username.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, on: :password_reset
  validates :password, length: { minimum: 12 }, if: -> { password.present? }
  validates :username, presence: true, uniqueness: true,
    length: { in: 3..30 }, format: { with: /\A[a-z0-9]+(?:[_-][a-z0-9]+)*\z/ }

  def reset_password(attributes)
    reset = false

    transaction do
      assign_attributes(attributes)
      if save(context: :password_reset)
        sessions.delete_all
        reset = true
      end
    end

    reset
  end
end
