module Admin
  class EntriesController < BaseController
    include Pagination

    PAGE_SIZE = 50

    before_action :set_entry, only: %i[show edit update destroy retry_image]

    def index
      @entries = paginate(Entry.recent.with_attached_image_thumbnail, per_page: PAGE_SIZE)
    end

    def show
    end

    def new
      @entry = Entry.new
    end

    def edit
    end

    def retry_image
      notice = @entry.retry_image_import! ? "Image import queued." : "No image URL to import."
      redirect_to admin_entry_path(@entry), notice: notice, status: :see_other
    end

    def create
      @entry = Entry.new(entry_params)

      if @entry.save_with_tags
        redirect_to admin_entry_path(@entry), notice: "Entry saved.", status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @entry.assign_attributes(entry_params)

      if @entry.save_with_tags
        redirect_to admin_entry_path(@entry), notice: "Entry updated.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @entry.destroy
        redirect_to admin_entries_path, notice: "Entry removed.", status: :see_other
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_entry
      @entry = Entry.find(params[:id])
    end

    def entry_params
      params.expect(entry: [ :title, :url, :image_url, :source_name, :media_kind, :notes, :tag_list ])
    end
  end
end
