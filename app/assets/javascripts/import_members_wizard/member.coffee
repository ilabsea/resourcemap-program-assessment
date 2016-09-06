onImportMembersWizard ->
  class @Member
    constructor: (data) ->
      @email = data[0]["value"]
      @none = data[1]["value"]
      @read = data[2]["value"]
      @write = data[3]["value"]
      @admin = data[4]["value"]
      @read_other = data[5]["value"]
      @edit_other = data[6]["value"]



