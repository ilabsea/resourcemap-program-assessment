xml.instruct! :xml, version: "1.0"
xml.rss rss_specification do
  xml.channel do
    xml.title site.name
    xml.lastBuildDate site.updated_at.rfc822
    xml.startEntryDate site.start_entry_date.rfc822
    xml.endEntryDate site.end_entry_date.rfc822

    site_item_rss xml, @result
  end
end
