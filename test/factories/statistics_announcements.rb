FactoryGirl.define do
  factory :statistics_announcement do
    sequence(:title) { |index| "Stats announcement #{index}" }
    summary "Summary of announcement"
    publication_type_id PublicationType::Statistics.id
    organisations { FactoryGirl.build_list :organisation, 1 }

    topics { FactoryGirl.build_list :topic, 1 }
    association :current_release_date, factory: :statistics_announcement_date
    association :creator, factory: :policy_writer
  end

  factory :cancelled_statistics_announcement, parent: :statistics_announcement do
    cancellation_reason "Cancelled for a reason"
    cancelled_at Time.zone.now
  end
end
