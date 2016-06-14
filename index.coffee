STEP_DEFAULT = 10

module.exports = class InfiniteScroll
	name: 'k-infinitescroll'
	updating: false
	element: false
	path: null

	create: ->
		element = @model.get 'element'
		@path = @model.get 'path'
		@step = parseInt(@model.get('step') or STEP_DEFAULT, 10)
		if @path and element and typeof window isnt 'undefined'
			window.addEventListener 'scroll', @infiniteScroll
			@element = document.getElementById element
			queryHash = @model.root._refLists.fromMap['_page.items'].idsSegments[1]
			@query = @model.root._queries.get queryHash

	infiniteScroll: =>
		last = @element and @element.lastElementChild
		if @query and last and not @updating and @inViewport(last)
			@updating = true
			setTimeout((=> @updating = false), 100)
			expr = @query.expression
			expr['$limit'] += @step
			@query.setQuery expr
			@query.send()

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
