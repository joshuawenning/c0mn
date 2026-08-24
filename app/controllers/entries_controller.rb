class EntriesController < ApplicationController
  allow_unauthenticated_access

  PAGE_SIZE = 48

  def index
    @query = params[:q].to_s.strip
    @active_tag = params[:tag].to_s.strip
    @page = [ params[:page].to_i, 1 ].max
    @tags = Tag.popular
    filtered_entries = Entry.tagged_with(@active_tag).search(@query)
    @entry_count = filtered_entries.count
    @total_entry_count = Entry.count
    @total_pages = (@entry_count.to_f / PAGE_SIZE).ceil
    @page = [ @page, [ @total_pages, 1 ].max ].min
    @entries = filtered_entries.includes(:tags).recent.offset((@page - 1) * PAGE_SIZE).limit(PAGE_SIZE)
  end

  def show
    @entry = Entry.includes(:tags).find(params[:id])
  end
end
