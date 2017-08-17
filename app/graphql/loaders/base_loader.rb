# Helper methods for all loaders
class Loaders::BaseLoader < GraphQL::Batch::Loader
  attr_reader :action

  def initialize(action:)
    @action = action
  end

  private

  def fulfill_all(keys, found_in_hash)
    found_in_hash.each do |key, object|
      fulfill(key, object)
    end

    not_found = keys - found_in_hash.keys
    not_found.each { |key| fulfill(key, nil) }
  end

  def can?(ctx_or_user, action, subject = nil)
    current_user =
      if ctx_or_user.is_a?(Hash)
        ctx_or_user['current_user']
      else
        ctx_or_user
      end

    Ability.allowed?(current_user, action, subject)
  end

  def filter_subject(ctx_or_user, action, subject = nil)
    if subject.is_a?(Array)
      subject.select { |item| can?(ctx_or_user, action, item) }
    elsif can?(ctx_or_user, action, subject)
      subject
    else
      nil
    end
  end

  def filter_by_action(promise, ctx, action = nil)
    if action
      promise.then { |result| filter_subject(ctx, action, result) }
    else
      promise
    end
  end
end
