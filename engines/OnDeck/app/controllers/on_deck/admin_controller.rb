require_dependency "on_deck/application_controller"

module OnDeck
  class AdminController < ApplicationController
    def index

    end

    def job_updatepps
      UpdateTbaAllPpsJob.perform_later
      render plain: 'done'
    end

    def job_updategds
      UpdateTbaAllGdsJob.perform_later
      render plain: 'done'
    end
  end
end
