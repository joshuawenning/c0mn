module Entries
  class Save
    MAX_ATTEMPTS = 2

    attr_reader :entry

    def initialize(entry)
      @entry = entry
    end

    def call
      attempts = 0

      begin
        attempts += 1
        persist
      rescue ActiveRecord::RecordInvalid => error
        add_tag_errors(error.record) unless error.record == entry
        false
      rescue ActiveRecord::RecordNotUnique
        entry.tags.reset

        if duplicate_url?
          entry.errors.add(:url, :taken)
          false
        elsif attempts < MAX_ATTEMPTS
          retry
        else
          entry.errors.add(:base, "could not be saved because another change was made; please try again")
          false
        end
      end
    end

    private
      def persist
        saved = false

        Entry.transaction do
          entry.valid?
          tags = resolve_tags

          if entry.errors.empty?
            entry.save!
            entry.tags = tags
            saved = true
          else
            raise ActiveRecord::Rollback
          end
        end

        saved
      end

      def resolve_tags
        tag_names.filter_map do |name|
          tag = Tag.find_or_initialize_by(name: name)
          if tag.valid?
            tag
          else
            add_tag_errors(tag, name)
            nil
          end
        end
      end

      def tag_names
        @tag_names ||= entry.tag_list.to_s.split(",").filter_map { |name| Tag.normalize_name(name) }.uniq
      end

      def add_tag_errors(tag, name = tag.name)
        entry.errors.add(:tag_list, "#{name}: #{tag.errors.full_messages.to_sentence}")
      end

      def duplicate_url?
        Entry.where(url: entry.url).where.not(id: entry.id).exists?
      end
  end
end
