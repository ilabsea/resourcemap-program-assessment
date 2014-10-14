onCollections ->
  class @Query
    constructor: (data) ->
      @id = data?.id
      @name = data?.name
      @conditions = data?.conditions #$.map(data?.conditions, (x) => new QueryCondition(x))