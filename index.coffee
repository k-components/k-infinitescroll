STEP_DEFAULT = '10'

module.exports = class InfiniteScroll
	view: __dirname
	name: 'k-infinitescroll'
	updating: false
	element: false
	datapath: null
	query: null
	step: null

	destroy: ->
		console.log 'destroy'
		@model.root.removeAllListeners 'insert', @datapath
		@scrollelement.removeEventListener('scroll', @infiniteScroll) if @scrollelement

	create: ->
		console.log 'create'
		@inverted = @model.get 'inverted'
		@datapath = @model.get 'datapath'
		@subscribedIdList = @model.get 'subscribedidlist'
		@element = document.getElementById(@model.get('element'))
		scrollelement = @model.get('scrollelement')
		@scrollelement = scrollelement && document.getElementById(scrollelement) or window
		@step = parseInt(@model.get('step') or STEP_DEFAULT, 10)
		@model.root.on 'insert', @datapath, @inserted
		@scrollelement.addEventListener 'scroll', @infiniteScroll

		fromMap = @model.root._refLists.fromMap[@datapath]
		if fromMap
			queryHash = fromMap.idsSegments[1]
			@query = @model.root._queries.get queryHash

	infiniteScroll: =>
		last = @element and (if @inverted then @element.firstElementChild else @element.lastElementChild)
		if last and @inViewport(last)
			@fetchQuery()

	inserted: (idx, arr) =>
		console.log idx, arr
		if idx
			ids = (a.id for a in arr when a?.id)
			@model.root.insert @subscribedIdList, idx, ids

	fetchQuery: =>
		if @query and !@updating
			@updating = true
			# calculate the new length of the query
			# @subscribedIdList (and so the number of items we see on the page) may have grown since started
			# and we must set the new length of the query to reflect that. Thus, we can't just increase
			# the $limit by @step
			newlength = @model.root.get(@subscribedIdList).length + @step
			@query.expression['$limit'] = newlength
			console.log '$limit', @query.expression['$limit']
			console.log @query.get()
			@query.fetch (err) =>
				console.log @query.get()
				console.error(err) if err
				setTimeout (=> @updating = false ), 500

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

