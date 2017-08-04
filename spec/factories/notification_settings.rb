FactoryGirl.define do
  factory :notification_setting do
    source factory: :project
    user { source&.creator || source&.owner }
    level 3
  end
end
