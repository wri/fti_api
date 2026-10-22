class MoveAboutPageEntriesToPageSections < ActiveRecord::Migration[8.0]
  class Page < ActiveRecord::Base
    self.table_name = "pages"
  end

  class PageTranslation < ActiveRecord::Base
    self.table_name = "page_translations"
  end

  class PageSection < ActiveRecord::Base
    self.table_name = "page_sections"
  end

  class PageSectionTranslation < ActiveRecord::Base
    self.table_name = "page_section_translations"
  end

  class AboutPageEntry < ActiveRecord::Base
    self.table_name = "about_page_entries"
  end

  class AboutPageEntryTranslation < ActiveRecord::Base
    self.table_name = "about_page_entry_translations"
  end

  def up
    about = Page.find_by(slug: "about")
    unless about
      about = Page.create!(slug: "about")
      # same as Translatable: every locale starts with the English text
      I18n.available_locales.each do |locale|
        PageTranslation.create!(page_id: about.id, locale: locale, title: "About")
      end
    end
    return if PageSection.exists?(page_id: about.id)

    AboutPageEntry.order(:position).each do |entry|
      section = PageSection.create!(
        page_id: about.id, position: entry.position, code: entry.code.presence,
        created_at: entry.created_at, updated_at: entry.updated_at
      )
      AboutPageEntryTranslation.where(about_page_entry_id: entry.id).find_each do |translation|
        PageSectionTranslation.create!(
          page_section_id: section.id, locale: translation.locale, title: translation.title, body: translation.body,
          created_at: translation.created_at, updated_at: translation.updated_at
        )
      end
    end
  end

  def down
    about = Page.find_by(slug: "about")
    return unless about

    PageSectionTranslation.where(page_section_id: PageSection.where(page_id: about.id).select(:id)).delete_all
    PageSection.where(page_id: about.id).delete_all
    PageTranslation.where(page_id: about.id).delete_all
    about.delete
  end
end
