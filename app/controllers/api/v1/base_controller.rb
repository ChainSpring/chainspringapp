class Api::V1::BaseController < ApplicationController

  rescue_from StandardError,                with: :internal_server_error
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def status
    render json: {status: 'ok'}, status: :ok
  end
  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def internal_server_error(exception)
    if Rails.env.development?
      response = { type: exception.class.to_s, message: exception.message, backtrace: exception.backtrace }
    else
      puts " #### erreur #### : #{{ type: exception.class.to_s, message: exception.message, backtrace: exception.backtrace }}"
      response = { error: "Internal Server Error" }
    end
    render json: response, status: :internal_server_error
  end
end
