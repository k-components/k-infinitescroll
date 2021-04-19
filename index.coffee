STEP_DEFAULT = '10'

module.exports = class InfiniteScroll
	name: 'k-infinitescroll'
	updating: false
	element: false
	query: null
	step: null

	destroy: ->
		@scrollelement.removeEventListener('scroll', @infiniteScroll) if @scrollelement
		@scrollelement = @query = null

		if @listener
			@model.root.removeListener 'insert', @listener

		@listener = null

	create: ->
		if @listener
			@model.root.removeListener 'insert', @listener

		@inverted = @model.get 'inverted'
		@datapath = @model.get 'datapath'
		@subscribedIdList = @model.get 'subscribedidlist'
		@element = document.getElementById(@model.get('element'))
		scrollelement = @model.get('scrollelement')
		@scrollelement = scrollelement && document.getElementById(scrollelement) or window
		@step = parseInt(@model.get('step') or STEP_DEFAULT, 10)
		@listener = @model.root.on 'insert', @datapath, @inserted

		setTimeout (=> @scrollelement.addEventListener 'scroll', @infiniteScroll(1)), 500

		hash = @model.get 'hash'
		@query = @model.root._queries.map[@model.root.get(hash)]

	infiniteScroll: (n = 1) =>
		=>
			if !document.body.contains(@element)
				@element = document.getElementById(@model.get('element'))

			last = @element and (if @inverted then @element.firstElementChild else @element.lastElementChild)

			if last and @inViewport(last)
				@fetchQuery()
			else if n < 5
				setTimeout (=> @infiniteScroll(n + 1)), 50

	lazyload: ->
		window.myLazyLoad.update()

	inserted: (idx, arr) =>
		if window.myLazyLoad
			setTimeout @lazyload, 10
			setTimeout @lazyload, 50
			setTimeout @lazyload, 100
			setTimeout @lazyload, 200

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
			@query.fetch (err) =>
				console.error(err) if err
				@updating = false

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

