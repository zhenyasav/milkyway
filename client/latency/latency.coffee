Template.latency.helpers 

	legend: -> ['median', 'peak', 'errors']

Template.latency.onDestroyed ->
	$(window).off 'resize', @onResize
	@onResize = null

Template.latency.onRendered ->

	root = @firstNode
	svg = d3.select @$('svg')[0]

	height = 150
	width = plotHeight = barWidth = 0
	margin = 35
	topmargin = 15
	errorMargin = 17
	errorRadius = 7
	yfloor = 0.5
	traffic = null

	latencyScale = d3.scale.linear()

	latencyFormat = (d) -> d3.format('1.1r')(d/1000) + 's'

	latencyAxis = d3.svg.axis()
	.scale latencyScale
	.orient 'left'
	.ticks 2
	.tickFormat latencyFormat

	svg.append 'g'
	.attr 'width', 20
	.attr 'class', 'axis vertical'
	.attr 'transform', "translate(#{margin}, #{topmargin})"


	timeScale = d3.time.scale()
	timeScale.ticks d3.time.hour, 1

	timeAxis = d3.svg.axis()
	.scale timeScale
	.tickSize 4, 7 
	.tickPadding 6

	errorAxis = d3.svg.axis()
	.scale timeScale
	.tickSize 4, 5
	.tickPadding 6
	.orient 'top'
	.tickFormat ''
	
	svg.append 'g'
	.attr 'height', 20
	.attr 'class', 'axis horizontal'

	svg.append 'g'
	.attr 'height', 20
	.attr 'class', 'axis errors'


	gridLines = svg.append 'g'
	.attr 'class', 'grid'
	.attr 'transform', "translate(#{margin}, #{topmargin})"

	peakSeries = svg.append 'g'
	.attr 'class', 'peak series'
	.attr 'transform', "translate(#{margin}, #{topmargin})"

	medianSeries = svg.append 'g'
	.attr 'class', 'median series'
	.attr 'transform', "translate(#{margin}, #{topmargin})"

	errors = svg.append 'g'
	.attr 'class', 'errors'

	resize = =>
		svg.attr 'width', width = root.clientWidth
		svg.attr 'height', height

		plotHeight = Math.round(height * yfloor - topmargin)

		latencyScale.range [plotHeight, 0]

		svg.select '.axis.vertical'
		.attr 'height', plotHeight
		.call latencyAxis

		timeScale.range [0, width - 2 * margin]

		svg.select '.axis.horizontal'
		.attr 'width', width - 2 * margin
		.attr 'transform', "translate(#{margin}, #{Math.round height * yfloor})"
		.call timeAxis

		svg.select '.axis.errors'
		.attr 'width', width - 2 * margin
		.attr 'transform', "translate(#{margin}, #{Math.round height * yfloor + topmargin + 20 + errorMargin + 2 * errorRadius + 2})"
		.call errorAxis

		barWidth = (width - 2 * margin) / traffic.length

		svg.selectAll '.bar rect'
		.attr 'width', barWidth

		peakSeries.selectAll '.bar'
		.attr 'transform', (d, i) -> 
			"translate(#{timeScale d.hour}, #{latencyScale d.latency.peak})"
		.select 'text'
		.attr 'x', barWidth / 2

		medianSeries.selectAll '.bar'
		.attr 'transform', (d, i) -> 
			"translate(#{timeScale d.hour}, #{latencyScale d.latency.median})"
		.select 'text'
		.attr 'x', barWidth / 2

		gridLines.selectAll 'line'
		.attr "transform", (d) -> "translate(0, #{latencyScale d})"
		.attr "x2", width - 2 * margin

		errors.attr 'transform', "translate(#{margin}, #{Math.round height * yfloor + topmargin + 26 + errorMargin})"
		.selectAll '.error'
		.attr "transform", (d) -> "translate(#{timeScale d.hour}, 0)"


	@onResize = _.debounce resize, 600
	$(window).on 'resize', @onResize


	@autorun =>
		now = d3.time.hour.round new Date

		app = Template.currentData()

		traffic = Traffic.find
			app: app._id
			hour: $ne: null
		.fetch()
		.map (t) -> _.extend t, hour: d3.time.hour.offset now, t.hour

		if traffic?.length

			resize()

			latencyExtent = d3.extent traffic, (t) -> t.latency.peak
			latencyScale.domain [0, latencyExtent[1]]

			svg.select '.axis.vertical'
			.call latencyAxis


			timeExtent = d3.extent traffic, (t) -> t.hour
			timeScale.domain [timeExtent[0], d3.time.hour.offset timeExtent[1], 1]

			svg.select '.axis.horizontal'
			.call timeAxis

			svg.select '.axis.errors'
			.call errorAxis


			peakBar = peakSeries.selectAll ".bar"
			.data traffic
			.enter()
			.append "g"
			.attr 'class', 'bar'
			.attr 'transform', (d, i) -> "translate(#{timeScale d.hour}, #{plotHeight})"

			peakBar.transition()
			.attr 'transform', (d, i) -> "translate(#{timeScale d.hour}, #{latencyScale d.latency.peak})"
			.duration 1000

			peakBar.append 'rect'
			.attr 'width', barWidth
			.attr 'height', 0
			.transition()
			.duration 1000
			.attr 'height', (d) -> plotHeight - latencyScale d.latency.peak

			peakBar.append 'text'
			.attr 'text-anchor', 'middle'
			.attr 'x', barWidth / 2
			.attr 'y', -3
			.text (d) -> latencyFormat d.latency.peak
			

			medianBar = medianSeries.selectAll '.bar'
			.data traffic
			.enter()
			.append 'g'
			.attr 'class', 'bar'
			.attr 'transform', (d, i) -> "translate(#{timeScale d.hour}, #{plotHeight})"

			medianBar.transition()
			.duration 1000
			.delay 600
			.attr 'transform', (d, i) -> "translate(#{timeScale d.hour}, #{latencyScale d.latency.median})"

			medianBar.append "rect"
			.attr 'width', barWidth
			.attr 'height', 0
			.transition()
			.duration 1000
			.delay 600
			.attr 'height', (d) -> plotHeight - latencyScale d.latency.median
			
			medianBar.append 'text'
			.attr 'text-anchor', 'middle'
			.attr 'x', barWidth / 2
			.attr 'y', -3
			.text (d) -> latencyFormat d.latency.median


			gridLines.selectAll 'line'
			.data latencyScale.ticks(4)
			.enter()
			.append "line"
			.attr "x2", width - 2 * margin
			.attr "transform", (d) -> "translate(0, #{latencyScale d})"
			

			err = errors.selectAll '.error'
			.data _.filter traffic, (t) -> t.errors
			.enter()
			.append "g"
			.attr "class", 'error'
			.attr "transform", (d) -> "translate(#{timeScale d.hour}, 0)"
			
			err.append "text"
			.attr "text-anchor", "middle"
			.text (d) -> d.errors

			err.append "circle"
			.attr "r", errorRadius
			.attr "cy", -4




