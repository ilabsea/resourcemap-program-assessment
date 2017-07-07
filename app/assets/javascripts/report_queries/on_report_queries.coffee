window.onReportQueries ?= (callback) -> $(-> callback() if $('#report-queries-main').length > 0)
