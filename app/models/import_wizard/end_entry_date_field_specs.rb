class ImportWizard::EndEntryDateFieldSpecs < ImportWizard::BaseFieldSpecs
  def process(row, site)
    site.end_entry_date = row[@column_spec[:index]]
  end
end