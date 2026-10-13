namespace :images do
  desc "Queue missing or failed local image imports in resumable batches"
  task backfill: :environment do
    result = EntryImageBackfill.call
    puts "Queued #{result[:queued]} image imports; skipped #{result[:skipped]} entries without an eligible image."
    puts "Ready and pending imports were left intact. Check failed imports in the admin after jobs finish."
  end
end
