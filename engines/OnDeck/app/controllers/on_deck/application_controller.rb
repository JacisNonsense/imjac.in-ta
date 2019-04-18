module OnDeck
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    respond_to :json, :xml
  end
end
