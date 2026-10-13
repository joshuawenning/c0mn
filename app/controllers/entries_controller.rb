class EntriesController < ApplicationController
  include Pagination

  allow_unauthenticated_access

  PAGE_SIZE = 48
  MAX_QUERY_LENGTH = 200

  def index
    filters = params.permit(:q, :tag)
    @query = filters[:q].to_s.strip.slice(0, MAX_QUERY_LENGTH)
    @active_tag = filters[:tag].to_s.strip
    @tags = Tag.popular
    filtered_entries = Entry.tagged_with(@active_tag).search(@query)
    @entries = paginate(filtered_entries.recent, per_page: PAGE_SIZE).includes(:tags).with_attached_image_card.load
    @total_entry_count = @query.blank? && @active_tag.blank? ? @entry_count : Entry.count
  end

  def show
    @entry = Entry.includes(:tags).with_attached_image_master.with_attached_image_card.find(params[:id])
  end
end
