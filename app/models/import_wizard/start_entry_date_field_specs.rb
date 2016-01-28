class ImportWizard::StartEntryDateFieldSpecs < ImportWizard::BaseFieldSpecs
  def process(row, site)
    site.start_entry_date = row[@column_spec[:index]]
  end
end