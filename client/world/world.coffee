@data = data = {}

@dataCenters = dataCenters = [
	'San Francisco'
	'Vancouver'
	'Washington, D.C.'
	'Sao Paulo'
	'Dublin'
	'Berlin'
	'Tokyo'
	'Singapore'
	'Sydney'
]

@dataCenterZones = dataCenterZones = [
	'US Southwest'
	'US Northwest'
	'US East'
	'South America'
	'EU Atlantic'
	'EU Mainland'
	'Japan'
	'Oceania'
	'Australia'
]

randomRange = (low, high) -> Math.random() * (high - low) + low
roundTo = (r, n) -> r * Math.floor n / r
clamp = (l, h, n) ->
	return l if n < l
	return h if n > h
	n

makeData = (w) ->
	w.objects.datacenters = _.clone w.objects.places

	window.data = data =
		world: w
		countries: topojson.feature(w, w.objects.countries).features
		cities: topojson.feature(w, w.objects.places).features

	# filter places
	filtered = _.filter w.objects.places.geometries, (g) -> 
		g.properties.name in dataCenters
	
	w.objects.datacenters.geometries = filtered

	data.datacenters = topojson.feature(w, w.objects.datacenters).features

	makeTraffic()


makeTraffic = ->

	limits = 
		minDistance: Math.PI * 0.3
		normDistance: Math.PI * 0.5
		time: 
			min: -24
			max: 0
		latency:
			median:
				min: 100
				max: 500
			peak:
				min: 400
				max: 1400
		dataCenters:
			perApp:
				min: 1
				max: dataCenters.length * 0.3
			normTrafficSources:
				min: 0.05
				max: 0.15
		volume:
			min: 10
			max: 5000
		errors:
			min: 1
			max: 10
			prob: 0.2

	latency = (d=limits.normDistance) ->
		normDistance = d / limits.normDistance
		peak = Math.round normDistance * randomRange limits.latency.peak.min, limits.latency.peak.max
		median = Math.round normDistance * randomRange limits.latency.median.min, limits.latency.median.max
		median = 0.7 * median + 0.3 * median * (peak - limits.latency.peak.min) / (limits.latency.peak.max - limits.latency.peak.min)
		{peak, median}

	distance = d3.geo.distance

	data.distantCities = {}
	data.datacenters.map (dataCentre) ->
		data.distantCities[dataCentre.properties.name] = _.filter data.cities, (city) ->
			limits.minDistance < distance dataCentre.geometry.coordinates, city.geometry.coordinates

	Apps.find().map (app) ->
		# allocate some servers in random data centers
		sitesCount = Math.round randomRange limits.dataCenters.perApp.min, limits.dataCenters.perApp.max
		dcSample = _.sample dataCenters, sitesCount
		Apps.update app._id,
			$set:
				availability: dcSample.map (dataCenter, i) ->
					name: dataCenterZones[dataCenters.indexOf(dataCenter)]
					size: Math.round randomRange App.min.size, App.max.size
					scale: clamp App.min.scale, App.max.scale, roundTo 5, randomRange App.min.scale, App.max.scale

		# generate some traffic records

		# traffic (hourly)
			# app: appid
			# latency:
			# 	median: number
			# 	peak: number
			# hour: -time
			# errors: count

		[limits.time.min .. limits.time.max].map (hour) ->
			Traffic.insert
				app: app._id
				latency: latency()
				hour: hour
				errors: if Math.random() > limits.errors.prob then 0 else Math.round randomRange limits.errors.min, limits.errors.max

		# traffic (geographic, daily)
			# app: appid
			# from: city
			# to: city
			# latency:
			# 	median: number
			# 	peak: number
			# volume: number

		dcSampleFeatures = dcSample.map (dc) -> _.find data.datacenters, (d) -> dc is d.properties.name

		dcSample.map (dc) -> 
			destination = _.find data.datacenters, (d) -> d.properties.name is dc
			cities = data.distantCities[destination.properties.name]

			# to this destination there is a random selection of source traffic
			citiesMin = Math.round cities.length * limits.dataCenters.normTrafficSources.min
			citiesMax = Math.round cities.length * limits.dataCenters.normTrafficSources.max
			citiesCount = Math.round randomRange citiesMin, citiesMax
			citiesSample = _.sample cities, citiesCount

			citiesSample.map (source) ->

				# find closest datacentre
				closestDestination = _.min dcSampleFeatures, (df) -> distance df.geometry.coordinates, source.geometry.coordinates

				dist = distance closestDestination.geometry.coordinates, source.geometry.coordinates

				Traffic.insert
					app: app._id
					from: source
					to: closestDestination
					distance: dist
					latency: latency dist
					volume: Math.round randomRange limits.volume.min, limits.volume.max

Template.world.helpers

	legendScales: ->
		instance = Template.instance()
		
		[latency, volume] = [instance.trafficLatencyScale, instance.trafficVolumeScale]

		if latency? and volume?
			latencyTicks = latency.ticks 3
			volumeTicks = volume.ticks 3

			latencyFormat = (d) -> d3.format('1.1f')(d/1000) + 's'

			result = for l, i in latencyTicks
				latency: latencyFormat l
				latencyOpacity: latency(l).toFixed(1)
				volume: volumeTicks[i]
				volumeHeight: volume(volumeTicks[i]).toFixed(1)
				
			result

Template.world.events
	'click .help': (e) ->
		$('.world').toggleClass 'show-legend'

	'click .legend .close': (e) ->
		$('.world').removeClass 'show-legend'


Template.world.onDestroyed ->
	$(window).off 'resize', @onResize
	@onResize = null

Template.world.onRendered ->

	root = @firstNode
	svg = d3.select @$('svg')[0]

	width = height = 0
	margin = 0

	draw = =>
		resize = ->
			svg.attr 'width', width = root.clientWidth - 2*margin
			svg.attr 'height', height = 360 - 2*margin + 70 + 70

			projection = d3.geo.mercator()
			.scale 120
			.translate [width/2, height/1.7]

			path = d3.geo.path().projection projection

			dcPath = d3.geo.path().projection projection
			.pointRadius 5

			cityPath = d3.geo.path().projection projection
			.pointRadius 1

			trafficPath = d3.geo.path().projection projection
			.pointRadius 2

			d3.selectAll('.country').attr 'd', path
			d3.selectAll('.city').attr 'd', cityPath
			d3.selectAll('.datacenter').attr 'd', dcPath
			d3.selectAll('.traffic').attr 'd', trafficPath
			
		svg.selectAll '.country'
		.data data.countries
		.enter().append 'path'
		.attr 'class', (d) -> 'country ' + d.id
		.attr 'opacity', 0
		.on 'click', (d) -> console.log d.id
		.transition()
		.duration 700
		.attr 'opacity', 1

		svg.selectAll '.city'
		.data data.cities
		.enter().append 'path'
		.attr 'class', 'city'
		.attr 'opacity', 0
		.attr 'stroke-width', 5
		.on 'click', (d) -> console.log d.properties.name
		.transition()
		.attr 'opacity', 1
		.attr 'stroke-width', 0
		.duration 700
		.delay 700
		

		geoTraffic = Traffic.find
			app: @data._id
			to: $ne: null
		.fetch()

		volumeExtent = d3.extent geoTraffic, (t) -> t.volume

		@trafficVolumeScale = trafficVolumeScale = d3.scale.linear()
		.domain volumeExtent
		.range [1, 5]

		latencyExtent = d3.extent geoTraffic, (t) -> t.latency.peak

		@trafficLatencyScale = trafficLatencyScale = d3.scale.linear()
		.domain latencyExtent
		.range [0.1, 0.5]

		
		svg.selectAll '.traffic'
		.data geoTraffic.map (traffic) ->
			type: "LineString"
			coordinates: [
				traffic.from.geometry.coordinates
				traffic.to.geometry.coordinates
			]
			volume: traffic.volume
			latency: traffic.latency.peak
		.enter()
		.append 'path'
		.attr 'class', 'traffic'
		.attr 'opacity', 0
		.attr 'stroke-width', (d) -> trafficVolumeScale d.volume
		.transition()
		.delay (d, i) -> 3000 + i * 3000 / geoTraffic.length
		.duration 600
		.attr 'opacity', (d) -> trafficLatencyScale d.latency


		occupiedCities = Apps.findOne(@data._id)?.availability
		.map (a) -> dataCenters[dataCenterZones.indexOf(a.name)]
		
		svg.selectAll '.datacenter'
		.data data.datacenters
		.enter().append 'path'
		.attr 'class', (d) -> "datacenter" + if d.properties.name in occupiedCities then " occupied" else ""
		.attr 'opacity', 0
		.attr 'stroke-width', 20
		.on 'click', (d) -> console.log d.properties.name
		.transition()
		.delay (d,i) -> 1000 + i * 2000 / data.datacenters.length
		.duration 1000
		.attr 'opacity', 1
		.attr 'stroke-width', 1


		resize()
		@onResize = _.debounce resize, 600
		$(window).on 'resize', @onResize

		Meteor.setTimeout =>
			@$ '.world'
			.addClass 'show-warnings'
		, 7000

	if not data?.world
		d3.json '/world.json', (err, w) -> 
			
			makeData w
	
			draw()
	else 
		draw()


	
	
