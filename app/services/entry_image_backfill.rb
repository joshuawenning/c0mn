class EntryImageBackfill
  def self.call
    queued = 0
    skipped = 0
    Entry.where(image_import_status: %w[none failed]).find_each(batch_size: 100) do |entry|
      entry.with_lock do
        # Recheck after locking in case another backfill or URL edit queued it.
        if %w[none failed].include?(entry.image_import_status) && entry.retry_image_import!
          queued += 1
        else
          skipped += 1
        end
      end
    end
    { queued: queued, skipped: skipped }
  end
end
