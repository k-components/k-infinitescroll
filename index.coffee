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
			console.log 'inserted', index, ids
			@model.root.insert @subscribedIdList, index, ids

	fetchQuery: =>
		if @query and !@updating
			@updating = true
			# calculate the new length of the query
			# @subscribedIdList (and so the number of items we see on the page) may have grown since started
			# and we must set the new length of the query to reflect that. Thus, we can't just increase
			# the $limit by @step
			newlength = @model.root.get(@subscribedIdList).length + @step
			@query.expression['$limit'] = newlength
			@query.fetch (err) =>
				console.error(err) if err
				setTimeout (=> @updating = false ), 500
				#@getItemsIds(@query.get())

	# bottom of the element doesn't have to show entirely, it's enough if the element is showing just partly (20 pixels from the bottom)
	inViewport: (el) =>
		if el and el.getBoundingClientRect
			rect = el.getBoundingClientRect()

			return (
				rect.top >= 0 &&
				rect.left >= 0 &&
				rect.bottom > 0 &&
				rect.bottom - 20 <= (window.innerHeight || document.documentElement.clientHeight) &&
				rect.right <= (window.innerWidth || document.documentElement.clientWidth)
			)

