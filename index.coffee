STEP_DEFAULT = 10

module.exports = class InfiniteScroll
	name: 'k-infinitescroll'
	updating: false
	element: false
	queryObject: null
	path: null
	collection: null

	create: ->
		element = @model.get 'element'
		qopath = @model.get 'qopath'
		@path = @model.get 'path'
		@step = parseInt(@model.get('step') or STEP_DEFAULT, 10)
		@collection = @model.get 'collection'
		if @collection and @path and element and qopath and typeof window isnt 'undefined'
			window.addEventListener 'scroll', @infiniteScroll
			@element = document.getElementById element
			@queryObject = @model.root.get qopath

	infiniteScroll: =>
		last = @element and @element.lastChild.previousSibling
		if @queryObject and last and not @updating and @inViewport(last)
			@updating = true
			postQuery = @model.root._queries.get @collection, @queryObject
			@queryObject['$limit'] += @step
			postQ = @model.root.query @collection, @queryObject
			@model.subscribe postQ, (err) =>
				@model.root.ref @path, postQ
				if postQuery
					@model.root.unsubscribe postQuery, (err) =>
						@updating = false
				else
					@updating = false

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
