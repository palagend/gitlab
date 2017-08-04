require 'spec_helper'

describe Subscribable, 'Subscribable' do
  let(:project)  { build_stubbed(:project) }
  let(:resource) { build_stubbed(:issue, project: project) }
  let(:user_1)   { build_stubbed(:user) }

  describe '#subscribed?' do
    context 'without project' do
      it 'returns false when no subscription exists' do
        expect(resource.subscribed?(user_1)).to be_falsey
      end

      it 'returns true when a subcription exists and subscribed is true' do
        resource.subscriptions.create(user: user_1, subscribed: true)

        expect(resource.subscribed?(user_1)).to be_truthy
      end

      it 'returns false when a subcription exists and subscribed is false' do
        resource.subscriptions.create(user: user_1, subscribed: false)

        expect(resource.subscribed?(user_1)).to be_falsey
      end
    end

    context 'with project' do
      it 'returns false when no subscription exists' do
        expect(resource.subscribed?(user_1, project)).to be_falsey
      end

      it 'returns true when a subcription exists and subscribed is true' do
        resource.subscriptions.create(user: user_1, project: project, subscribed: true)

        expect(resource.subscribed?(user_1, project)).to be_truthy
      end

      it 'returns false when a subcription exists and subscribed is false' do
        resource.subscriptions.create(user: user_1, project: project, subscribed: false)

        expect(resource.subscribed?(user_1, project)).to be_falsey
      end
    end
  end

  describe '#subscribers' do
    it 'returns [] when no subcribers exists' do
      expect(resource.subscribers(project)).to be_empty
    end

    it 'returns the subscribed users' do
      user_2 = build_stubbed(:user)
      resource.subscriptions.create(user: user_1, subscribed: true)
      resource.subscriptions.create(user: user_2, project: project, subscribed: true)
      resource.subscriptions.create(user: build_stubbed(:user), project: project, subscribed: false)

      expect(resource.subscribers(project)).to contain_exactly(user_1, user_2)
    end
  end

  describe '#toggle_subscription' do
    context 'without project' do
      it 'toggles the current subscription state for the given user' do
        expect(resource.subscribed?(user_1)).to be_falsey

        resource.toggle_subscription(user_1)

        expect(resource.subscribed?(user_1)).to be_truthy
      end
    end

    context 'with project' do
      it 'toggles the current subscription state for the given user' do
        expect(resource.subscribed?(user_1, project)).to be_falsey

        resource.toggle_subscription(user_1, project)

        expect(resource.subscribed?(user_1, project)).to be_truthy
      end
    end
  end

  describe '#subscribe' do
    context 'without project' do
      it 'subscribes the given user' do
        expect(resource.subscribed?(user_1)).to be_falsey

        resource.subscribe(user_1)

        expect(resource.subscribed?(user_1)).to be_truthy
      end
    end

    context 'with project' do
      it 'subscribes the given user' do
        expect(resource.subscribed?(user_1, project)).to be_falsey

        resource.subscribe(user_1, project)

        expect(resource.subscribed?(user_1, project)).to be_truthy
      end
    end
  end

  describe '#unsubscribe' do
    context 'without project' do
      it 'unsubscribes the given current user' do
        resource.subscriptions.create(user: user_1, subscribed: true)
        expect(resource.subscribed?(user_1)).to be_truthy

        resource.unsubscribe(user_1)

        expect(resource.subscribed?(user_1)).to be_falsey
      end
    end

    context 'with project' do
      it 'unsubscribes the given current user' do
        resource.subscriptions.create(user: user_1, project: project, subscribed: true)
        expect(resource.subscribed?(user_1, project)).to be_truthy

        resource.unsubscribe(user_1, project)

        expect(resource.subscribed?(user_1, project)).to be_falsey
      end
    end
  end
end
