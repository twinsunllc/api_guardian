# frozen_string_literal: true

module ApiGuardian
  class BaseMetalController < ActionController::API
    include AbstractController::Callbacks
    include ActionController::Rescue
    include ApiGuardian::DoorkeeperHelpers
  end
end
