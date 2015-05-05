
currencyFormat = '0,0'


Template.allocation.helpers

	minScale: -> App.min.scale

	maxScale: -> App.max.scale

	zones: ->
		_.difference dataCenterZones, _.map @availability, (a) -> a.name

	checked: (v) ->
		checked: 'checked' if @value.size is v

	estimate: ->
		numeral(App.zoneEstimate(@value)).format currencyFormat

	totalEstimate: (field) ->
		total = App.monthlyEstimate field
		numeral(total).format currencyFormat

	pendingDifference: ->
		total = App.monthlyEstimate @availability

		pending = App.monthlyEstimate @pending?.availability

		numeral(pending - total).format '+' + currencyFormat

	isPending: -> 'pending' if @pending?.availability

	availability: -> @pending?.availability ? @availability


Template.allocation.events

	'change .size .radio input': (e) ->
		size = Number $(e.target).val()
		if isFinite(size) and not isNaN(size)
			app = Template.parentData 1
			app?.setAvailabilitySize @value.name, size

	'change .scale': (e) ->
		scale = e.originalEvent.value
		if isFinite(scale) and not isNaN(scale)
			app = Template.parentData 1
			app?.setAvailabilityScale @value.name, scale

	'change select.add-zone': (e) -> 
		if e.target.value
			@addAvailability e.target.value
			$(e.target).val ''

	'click .zone .button.delete': (e) ->
		if app = Template.parentData 1
			app?.removeAvailability @value.name
			

