module Pagination
  extend ActiveSupport::Concern

  private
    def paginate(records, per_page:)
      @entry_count = records.count
      @total_pages = (@entry_count + per_page - 1) / per_page
      @page = params.permit(:page)[:page].to_i.clamp(1, [ @total_pages, 1 ].max)

      records.offset((@page - 1) * per_page).limit(per_page)
    end
end
