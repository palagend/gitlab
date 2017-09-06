module Groups
  class TransferService < Groups::BaseService
    include TransferErrorMessages

    TransferError = Class.new(StandardError)
    attr_reader :error

    def initialize(group, user, params = {})
      super
      @error = nil
    end

    private

    def with_transfer_error_handling
      yield
    rescue TransferError => e
      @error = "Transfer failed: " + e.message
      false
    rescue Gitlab::UpdatePathError
      @error = friendly_update_path_error
      false
    end

    def raise_transfer_error(message)
      if message.is_a?(Symbol)
        raise TransferError, error_messages[message]
      else
        raise TransferError, message
      end
    end
  end
end
