require_dependency "on_deck/application_controller"

module OnDeck
  class ApiController < ApplicationController

    def recommendations
      respond_with(UpcomingRecommendation.all.map { |x| JSON.parse(x.data) })
    end

  end
end