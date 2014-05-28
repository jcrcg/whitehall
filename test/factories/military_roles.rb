FactoryGirl.define do
  factory :military_role do
    name "Chief of the Air Staff"
    status "active"
    after :build do |role, evaluator|
      role.organisations = [FactoryGirl.build(:organisation)] unless evaluator.organisations.any?
    end
  end
end
