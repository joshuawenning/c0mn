module Admin
  class EntriesController < BaseController
    PAGE_SIZE = 50

    before_action :set_entry, only: %i[show edit update destroy]

    def index
      @page = [ params[:page].to_i, 1 ].max
      @entry_count = Entry.count
      @total_pages = (@entry_count.to_f / PAGE_SIZE).ceil
      @page = [ @page, [ @total_pages, 1 ].max ].min
      @entries = Entry.recent.offset((@page - 1) * PAGE_SIZE).limit(PAGE_SIZE)
    end

    def show
    end

    def new
      @entry = Entry.new
    end

    def edit
    end

    def create
      @entry = Entry.new(entry_params)

      if Entries::Save.new(@entry).call
        redirect_to admin_entry_path(@entry), notice: "Entry saved."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @entry.assign_attributes(entry_params)

      if Entries::Save.new(@entry).call
        redirect_to admin_entry_path(@entry), notice: "Entry updated."
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
      params.require(:entry).permit(:title, :url, :image_url, :source_name, :media_kind, :notes, :tag_list)
    end
  end
end
