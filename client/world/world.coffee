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
				max: 0.08
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


getTrafficScales = (geoTraffic) ->

	volumeExtent = d3.extent geoTraffic, (t) -> t.volume

	trafficVolumeScale = d3.scale.linear()
	.domain volumeExtent
	.range [1, 6]

	latencyExtent = d3.extent geoTraffic, (t) -> t.latency.peak

	trafficLatencyScale = d3.scale.linear()
	.domain latencyExtent
	.range [0.1, 0.5]

	[trafficVolumeScale, trafficLatencyScale]


Template.world.helpers

	legendScales: ->
		instance = Template.instance()
		
		_data = Template.currentData()

		geoTraffic = Traffic.find 
			app: _data?._id
			to: $ne: null
		.fetch()

		[volume, latency] = getTrafficScales geoTraffic

		if latency? and volume?
			latencyTicks = latency.ticks 3
			volumeTicks = volume.ticks 3

			latencyFormat = (d) -> d3.format('1.1f')(d/1000) + 's'

			result = for i in [0..Math.max(latencyTicks.length, volumeTicks.length)-1]
				latency: latencyFormat latencyTicks[i]
				latencyOpacity: latency(latencyTicks[i]).toFixed(1)
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

	width = height = 0
	margin = 0
	geoTraffic = null

	projection = d3.geo.mercator()

	zoom = d3.behavior.zoom()
	.scaleExtent [1, 9]
	.on 'zoom', move


	svg = d3.select @$('svg')[0]
	
	map = svg.append 'g'

	move = ->
		t = d3.event.translate
		s = d3.event.scale

		zscale = s
		h = height / 4

		t[0] = Math.min(width / height * (s - 1), Math.max(width * (1 - s), t[0]))
		t[1] = Math.min(h * (s - 1) + h * s, Math.max(height * (1 - s) - h * s, t[1]))

		zoom.translate t

		map.attr 'transform', Utils.log 'translate(' + t + ')scale(' + s + ')'
		#adjust the country hover stroke width based on zoom level
		# d3.selectAll('.country').style 'stroke-width', 1.5 / s

	path = d3.geo.path().projection projection

	dcPath = d3.geo.path().projection projection
	.pointRadius 5

	cityPath = d3.geo.path().projection projection
	.pointRadius 1

	trafficPath = d3.geo.path().projection projection
	.pointRadius 2


	draw = =>
		resize = ->
			svg.attr 'width', width = root.clientWidth - 2*margin
			
			projectionVOffsetScale = d3.scale.linear()
			.domain [100, 1920]
			.range [1.9, 1.4]

			heightScale = d3.scale.linear()
			.domain [100, 1920]
			.range [200, 700]

			svg.attr 'height', height = heightScale(width) - 2 * margin + 70 + 70

			projection
			.scale width / 2 / Math.PI
			.translate [width/2, height/projectionVOffsetScale width]

			map.selectAll('.country').attr 'd', path
			map.selectAll('.city').attr 'd', cityPath
			map.selectAll('.datacenter').attr 'd', dcPath
			map.selectAll('.traffic').attr 'd', (d) ->
				trafficPath
					type: "LineString"
					coordinates: [
						d.from.geometry.coordinates
						d.to.geometry.coordinates
					]
			
		map.selectAll '.country'
		.data data.countries
		.enter().append 'path'
		.attr 'class', (d) -> 'country ' + d.id
		.attr 'opacity', 0
		.on 'click', (d) -> console.log d.id
		.transition()
		.duration 700
		.attr 'opacity', 1

		map.selectAll '.city'
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
		
		@autorun =>

			app = Template.currentData()

			geoTraffic = Traffic.find
				app: app._id
				to: $ne: null
			.fetch()


			[trafficVolumeScale, trafficLatencyScale] = getTrafficScales geoTraffic


			occupancyScale = d3.scale.linear()
			.domain [App.min.scale, App.max.scale]
			.range [1, 10]

			
			traffic = map.selectAll '.traffic'
			.data geoTraffic, (d) -> d._id

			traffic.exit()
			.transition()
			.duration 600
			.attr 'opacity', 0
			.remove()

			traffic.enter()
			.append 'path'
			.attr 'class', 'traffic'
			.attr 'opacity', 0
			.attr 'stroke-width', (d) -> trafficVolumeScale d.volume
			.transition()
			.delay (d, i) -> 1600 + i * 2000 / geoTraffic.length
			.duration 600
			.attr 'opacity', (d) -> trafficLatencyScale d.latency.peak


			occupiedCities = Apps.findOne(app._id)?.availability
			.map (a) -> dataCenters[dataCenterZones.indexOf(a.name)]

			dataCtr = map.selectAll '.datacenter'
			.data data.datacenters, (d) -> Math.random()

			dataCtr.exit()
			.transition()
			.duration 600
			.attr 'opacity', 0
			.remove()

			dataCtr.enter()
			.append 'path'
			.attr 'class', (d) -> "datacenter" + if d.properties.name in occupiedCities then " occupied" else ""
			.attr 'opacity', 0
			.attr 'stroke-width', (d) -> if d.properties.name in occupiedCities then 50 else 1
			.on 'click', (d) -> console.log d.properties.name
			.transition()
			.delay (d,i) -> 
				n = d.properties.name
				if n in occupiedCities
					occupiedCities.indexOf(n) * 600 / occupiedCities.length
				else
					0
			.duration 1000
			.attr 'opacity', 1
			.attr 'stroke-width', (d) ->
				n = d.properties.name
				if n in occupiedCities
					if app?.availability?.length
						zone = dataCenterZones[dataCenters.indexOf(n)]
						av = _.find app.availability, (v) -> v.name is zone
						return occupancyScale av.scale if av?
				1


			resize()

		if not @onResize
			@onResize = _.debounce resize, 600
			$(window).on 'resize', @onResize

		Meteor.setTimeout =>
			@$ '.world'
			.addClass 'show-warnings'
		, 4000

	if not data?.world
		d3.json '/world.json', (err, w) -> 
			
			makeData w
	
			draw()
	else 
		draw()


Meteor.startup ->
	if not data?.world
		d3.json '/world.json', (err, w) ->
			makeData w


	
	
