zones = [
	'US North West'
	'US South West'
	'US East'
	'South America'
	'UK'
	'Germany'
	'Japan'
	'Philipines'
	'Australia'
]

prices = [0.05, 0.1] # $ per inst hour

currencyFormat = '0,0'

priceEstimate = (v) ->
	if price = prices[v.size]
		if scale = v.scale
			price * scale * 24 * 30
	else
		0

Template.allocation.helpers

	minScale: -> App.min.scale

	maxScale: -> App.max.scale

	zones: -> zones

	checked: (v) ->
		checked: 'checked' if @value.size is v

	estimate: ->
		numeral(priceEstimate(@value)).format currencyFormat

	totalEstimate: ->
		total = _.reduce @availability ? [], (m, n) ->
			m + priceEstimate n
		, 0
		numeral(total).format currencyFormat

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