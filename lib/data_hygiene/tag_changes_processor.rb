class TagChangesProcessor

  def initialize(csv_location)
    @csv_location = csv_location
  end

  def process
    tag_changes_list.each do |changes|
      @source_topic_id = changes["remove_topic"]
      @destination_topic_id = changes["add_topic"]
      processor
    end
  end

private

  attr_reader :csv_location

  def tag_changes_list
    csv = CSV::parse(File.open(csv_location.to_s, 'r') {|f| f.read })
    fields = csv.shift
    csv.collect { |record| Hash[*fields.zip(record).flatten ] }
  end

  def processor
    published_editions = get_published_editions
    log "Updating #{taggings.count} taggings of editions (#{published_editions.count} published) to change #{@source_topic_id} to #{@destination_topic_id}"
    update_taggings(taggings)
    register_editions(published_editions)
  end

  def update_taggings(taggings)
    taggings.reject { |tagging| tagging.edition.nil? }.each do |tagging|
      if tagging.edition.specialist_sector_tags.include? @destination_topic_id
        remove_tagging(tagging)
      else
        change_tagging(tagging)
      end
    end
  end

  def remove_tagging(tagging)
    edition = tagging.edition
    log "removing tagging on '#{edition.slug}' edition #{edition.id}"
    tagging.destroy

    add_editorial_remark(edition,
      "Bulk retagging from topic '#{@source_topic_id}' to '#{@destination_topic_id}' resulted in duplicate tag - removed it"
    )
  end

  def change_tagging(tagging)
    edition = tagging.edition
    log "tagging '#{edition.slug}' edition #{edition.id}"
    tagging.tag = @destination_topic_id
    tagging.save!

    add_editorial_remark(edition,
      "Bulk retagging from topic '#{@source_topic_id}' to '#{@destination_topic_id}' changed tag"
    )
  end

  def get_published_editions
    taggings.map { |tagging|
      tagging.edition.latest_published_edition
    }.compact.uniq
  end

  def taggings
    SpecialistSector.where(tag: @source_topic_id)
  end

  def register_editions(editions)
    editions.each do |edition|
      log "registering '#{edition.slug}'"
      edition.reload
      register_with_panopticon(edition)
      register_with_publishing_api(edition)
      register_with_search(edition)
    end
  end

  def register_with_panopticon(edition)
    registerable_edition = RegisterableEdition.new(edition)
    registerer           = Whitehall.panopticon_registerer_for(registerable_edition)
    registerer.register(registerable_edition)
  end

  def register_with_publishing_api(edition)
    PublishingApiWorker.perform_async(edition.class.name, edition.id, update_type: 'republish')
  end

  def register_with_search(edition)
    ServiceListeners::SearchIndexer.new(edition).index!
  end

  def add_editorial_remark(edition, message)
    if edition.nil?
      log " - no edition (probably deleted)"
    elsif Edition::FROZEN_STATES.include?(edition.state)
      log " - edition is frozen; skipping editorial remarks"
    else
      log " - adding editorial remark"
      edition.editorial_remarks.create!(
        author: gds_user,
        body: message
      )
    end
  end

  def gds_user
    @gds_user ||= User.find_by_email("govuk-whitehall@digital.cabinet-office.gov.uk")
  end

  def log(message)
    puts message
  end
end