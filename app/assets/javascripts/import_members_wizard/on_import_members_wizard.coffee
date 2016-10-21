window.onImportMembersWizard ?= (callback) -> $(-> callback() if $('#import-members-wizard-main').length > 0)

window.onImportMembersInProgress ?= (callback) -> $(-> callback() if $('#import-members-in-progress').length > 0)