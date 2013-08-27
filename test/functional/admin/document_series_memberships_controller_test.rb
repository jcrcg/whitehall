require 'test_helper'

class Admin::DocumentSeriesMembershipsControllerTest < ActionController::TestCase
  setup do
    @series = create(:document_series, :with_group)
    login_as create(:policy_writer)
  end

  should_be_an_admin_controller

  test 'JS POST #create adds the document to the series' do
    skip
    document = create(:publication).document
    xhr :post, :create, document_series_id: @series, id: document.id

    assert_response :success
    assert_template :create
    assert @series.documents.include?(document)
  end

  test 'JS DELETE #destroy removes a document from the series' do
    skip
    document = create(:publication).document
    @series.documents << document
    xhr :delete, :destroy, document_series_id: @series, id: document.id

    assert_response :success
    assert_template :destroy
    refute @series.documents(true).include?(document)
  end

  view_test 'JSON GET #search returns filter results as JSON' do
    skip
    publication = create(:publication, title: 'search term')

    get :search, document_series_id: @series, title: 'search term', format: :json

    assert_response :success

    response_as_hash = JSON.parse(response.body)
    assert_equal true, response_as_hash['results_any?']
    assert_equal 1, response_as_hash['results'].size

    publication_json = response_as_hash['results'][0]
    assert_equal publication.id, publication_json['id']
    assert_equal publication.document_id, publication_json['document_id']
    assert_equal publication.title, publication_json['title']
    assert_equal 'publication', publication_json['type']
    assert_equal publication.display_type, publication_json['display_type']
  end
end
