# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :timelog do
    time_spent 3600
    issue
    user { issue.project.creator }
  end
end
