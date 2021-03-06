describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'

  describe 'SitesViewModel', ->
    beforeEach ->
      @collection = new Collection id: 1
      window.model = new MainViewModel [@collection]
      @model = window.model

    describe 'selected hierarchy', ->
      beforeEach ->
        @field = new Field { id: 1, code: 'admu', name: 'Admin Unit', kind: 'select_one', writeable: true }
        @col_hierarchy = new CollectionHierarchy(@collection, @field)
        @hierarchyItem = new HierarchyItem(@col_hierarchy, @field, { id: 1, label: 'group 1' })

      it 'should select hierarchy', ->
        @model.selectHierarchy(@hierarchyItem)
        expect(@model.selectedHierarchy()).toBe(@hierarchyItem)

      it 'should unselect selectedField when selecting hierarchy', ->
        # reloadMapSites calls @map.getBounds() and map is undefined in this context
        window.model.reloadMapSites = ->

        site = new Site(@col_hierarchy, { name: "site 1"})
        @model.selectedSite(site)
        expect(@model.selectedSite()).toBe(site)

        @model.selectHierarchy(@hierarchyItem)
        expect(@model.selectedSite()).toBe(null)








