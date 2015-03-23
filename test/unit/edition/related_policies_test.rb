require "test_helper"
require 'gds_api/test_helpers/content_register'

class Edition::RelatedPoliciesTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::ContentRegister

  test "#destroy should also remove the relationship to existing policies" do
    edition = create(:draft_consultation, related_editions: [create(:draft_policy)])
    relation = edition.outbound_edition_relations.first
    edition.destroy
    refute EditionRelation.exists?(relation.id)
  end

  test "can set the policies without removing the other documents" do
    edition = create(:world_location_news_article)
    worldwide_priority = create(:worldwide_priority)
    old_policy = create(:policy)
    edition.related_editions = [worldwide_priority, old_policy]

    new_policy = create(:policy)
    edition.related_policy_ids = [new_policy.id]
    assert_equal [worldwide_priority], edition.worldwide_priorities
    assert_equal [new_policy], edition.related_policies
  end

  test '#related_policy_ids returns the related policy ids for a persisted record' do
    policy = create(:policy)
    edition = create(:news_article, related_documents: [policy.document])

    assert_equal [policy.id], edition.related_policy_ids
  end

  test '#releated_policy_ids returns the related policy ids for a non-persisted record' do
    policy = create(:policy)
    edition = build(:news_article, related_documents: [policy.document])

    assert_equal [policy.id], edition.related_policy_ids
  end

  test '#related_policy_ids returns the related policy ids when set with the setter' do
    policy = create(:policy)
    edition = build(:news_article)
    edition.related_policy_ids = [policy.id]

    assert_equal [policy.id], edition.related_policy_ids
  end

  test '#related_policy_ids does not include non-policies' do
    policy = create(:policy)
    edition = create(:news_article,
      related_documents: [policy.document, create(:detailed_guide).document])

    assert_equal [policy.id], edition.related_policy_ids
  end

  test '#related_policy_ids does not fall over with deleted documents' do
    policy = create(:deleted_policy)
    edition = create(:news_article, related_documents: [policy.document])

    assert_equal [], edition.related_policy_ids
  end

  test 'can assign, save and read content_ids for related policies' do
    content_id = SecureRandom.uuid
    edition = create(:news_article)
    edition.policy_content_ids = [content_id]

    assert_equal [content_id], edition.reload.policy_content_ids
  end

  test 're-assigning already-assigned content_ids does not create duplicates' do
    content_id_1 = SecureRandom.uuid
    content_id_2 = SecureRandom.uuid
    edition = create(:news_article, policy_content_ids: [content_id_1])

    assert_equal [content_id_1], edition.policy_content_ids

    edition.policy_content_ids = [content_id_1, content_id_2]

    assert_equal [content_id_1, content_id_2], edition.reload.policy_content_ids
  end
end
