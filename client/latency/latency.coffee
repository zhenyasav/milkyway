Template.latency.onDestroyed ->
	$(window).off 'resize', @onResize
	@onResize = null

Template.latency.onRendered ->

	root = @firstNode
	svg = d3.select @$('svg')[0]

	width = height = plotHeight = barWidth = 0
	margin = 30
	topmargin = 5
	yfloor = 0.75
	traffic = null

	latencyScale = d3.scale.linear()

	latencyAxis = d3.svg.axis()
	.scale latencyScale
	.orient 'left'
	.ticks 1
	.tickFormat (t) -> 
		console.log t
		(t/1000).toFixed(0) + 's'

	svg.append 'g'
	.attr 'width', 20
	.attr 'class', 'axis vertical'
	.attr 'transform', "translate(#{margin}, #{topmargin})"


	timeScale = d3.scale.linear()

	timeAxis = d3.svg.axis()
	.scale timeScale
	
	svg.append 'g'
	.attr 'height', 20
	.attr 'class', 'axis horizontal'


	peakSeries = svg.append 'g'
	.attr 'class', 'peak series'
	.attr 'transform', "translate(#{margin}, #{topmargin})"

	medianSeries = svg.append 'g'
	.attr 'class', 'median series'
	.attr 'transform', "translate(#{margin}, #{topmargin})"


	resize = =>
		svg.attr 'width', width = root.clientWidth
		svg.attr 'height', height = 100

		plotHeight = Math.round(height * yfloor - topmargin)

		latencyScale.range [plotHeight, 0]

		latencyAxis.scale latencyScale

		svg.select '.axis.vertical'
		.attr 'height', Math.round height * yfloor - topmargin
		.call latencyAxis

		timeScale.range [0, width - 2*margin]

		svg.select '.axis.horizontal'
		.attr 'width', width - 2 * margin
		.attr 'transform', "translate(#{margin}, #{height * yfloor})"
		.call timeAxis

		barWidth = (width - 2 * margin) / traffic.length

		svg.selectAll '.bar'
		.attr 'width', barWidth

		peakSeries.selectAll '.bar'
		.attr 'transform', (d, i) -> "translate(#{barWidth * i}, #{latencyScale d.latency.peak})"

		medianSeries.selectAll '.bar'
		.attr 'transform', (d, i) -> "translate(#{barWidth * i}, #{latencyScale d.latency.median})"


	@onResize = _.debounce resize, 600
	$(window).on 'resize', @onResize


	@autorun =>
		traffic = Traffic.find
			app: @data._id
			hour: $ne: null
		.fetch()

		if traffic?.length

			resize()

			latencyExtent = d3.extent traffic, (t) -> t.latency.peak
			latencyScale.domain [0, latencyExtent[1]]


			timeExtent = d3.extent traffic, (t) -> t.hour
			timeScale.domain timeExtent
			

			peakSeries.selectAll ".bar"
			.data traffic
			.enter()
			.append "rect"
			.attr 'class', 'bar'
			.attr 'width', barWidth
			.attr 'height', 0
			.attr 'transform', (d, i) -> "translate(#{barWidth * i}, #{plotHeight})"
			.transition()
			.duration 1000
			.attr 'height', (d) -> plotHeight - latencyScale d.latency.peak
			.attr 'transform', (d, i) -> "translate(#{barWidth * i}, #{latencyScale d.latency.peak})"


			medianSeries.selectAll '.bar'
			.data traffic
			.enter()
			.append "rect"
			.attr 'class', 'bar'
			.attr 'width', barWidth
			.attr 'height', 0
			.attr 'transform', (d, i) -> "translate(#{barWidth * i}, #{plotHeight})"
			.transition()
			.duration 1000
			.delay 600
			.attr 'height', (d) -> plotHeight - latencyScale d.latency.median
			.attr 'transform', (d, i) -> "translate(#{barWidth * i}, #{latencyScale d.latency.median})"


	

