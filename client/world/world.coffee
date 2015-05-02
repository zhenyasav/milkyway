@data = data = {}

dataCenters = [
	'San Francisco'
	'Tokyo'
	'Singapore'
	'Sydney'
	'Berlin'
	'Dublin'
	'Sao Paulo'
	'Washington, D.C.'
	'Vancouver'
]

Template.world.onDestroyed ->
	$(window).off 'resize', @onResize
	@onResize = null

Template.world.onRendered ->

	root = @firstNode
	svg = d3.select @$('svg')[0]

	width = height = 0
	margin = 0

	draw = =>
		svg.selectAll '.country'
		.data data.countries
		.enter().append 'path'
		.attr 'class', (d) -> 'country ' + d.id
		.attr 'opacity', 0
		.on 'click', (d) -> console.log d.id
		.transition()
		.duration 1000
		.delay (d, i) -> i * 1000 / data.countries.length
		.attr 'opacity', 1

		svg.selectAll '.city'
		.data data.cities
		.enter().append 'path'
		.attr 'class', 'city'
		.attr 'opacity', 0
		.on 'click', (d) -> console.log d.properties.name
		.transition()
		.delay (d,i) -> 1000 + i * 1000 / data.cities.length
		.duration 350
		.attr 'opacity', 1
		
		svg.selectAll '.datacenter'
		.data data.datacenters
		.enter().append 'path'
		.attr 'class', 'datacenter'
		.attr 'opacity', 0
		.on 'click', (d) -> console.log d.properties.name
		.transition()
		.delay (d,i) -> 2000 + i * 1000 / data.datacenters.length
		.duration 1000
		.attr 'opacity', 1

		resize = ->
			svg.attr 'width', width = root.clientWidth - 2*margin
			svg.attr 'height', height = 440 - 2*margin

			projection = d3.geo.mercator()
			.scale 120
			.translate [width/2, height/1.6]

			path = d3.geo.path().projection projection
			.pointRadius 3

			cityPath = d3.geo.path().projection projection
			.pointRadius 1

			d3.selectAll('.country').attr 'd', path
			d3.selectAll('.city').attr 'd', cityPath
			d3.selectAll('.datacenter').attr 'd', path

		resize()
		@onResize = _.debounce draw, 200
		$(window).on 'resize', @onResize

	if not data?.world
		d3.json '/world.json', (err, w) -> 
			
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
	
			draw()
	else 
		draw()


	
	
