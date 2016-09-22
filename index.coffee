STEP_DEFAULT = '10'

module.exports = class InfiniteScroll
	name: 'k-infinitescroll'
	updating: false
	element: false
	datapath: null
	query: null
	step: null

	destroy: ->
		window.removeEventListener 'scroll', @infiniteScroll

	create: ->
		@datapath = @model.get 'datapath'
		@subscribedIdList = @model.get 'subscribedidlist'
		@element = document.getElementById(@model.get('element'))
		@step = parseInt(@model.get('step') or STEP_DEFAULT, 10)
		@model.root.on 'insert', @datapath, @inserted

		if typeof window isnt 'undefined'
			window.addEventListener 'scroll', @infiniteScroll
			fromMap = @model.root._refLists.fromMap[@datapath]
			if fromMap
				queryHash = fromMap.idsSegments[1]
				@query = @model.root._queries.get queryHash

	infiniteScroll: =>
		last = @element and @element.lastElementChild
		if last and @inViewport(last)
			@fetchQuery()

	inserted: (index, arr) =>
		if index
			ids = (a.id for a in arr when a?.id)
			@model.root.insert @subscribedIdList, 0, ids

	fetchQuery: =>
		if @query and !@updating
			@updating = true
			@query.expression['$limit'] += @step
			@query.fetch (err) =>
				console.error(err) if err
				@updating = false
				#@getItemsIds(@query.get())

	inViewport: (el) =>
		if el and el.getBoundingClientRect
			rect = el.getBoundingClientRect()

			return (
				rect.top >= 0 &&
				rect.left >= 0 &&
				rect.bottom > 0 &&
				rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
				rect.right <= (window.innerWidth || document.documentElement.clientWidth)
			)

