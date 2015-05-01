world = null

Template.world.rendered = ->

	root = @firstNode
	svg = d3.select @$('svg')[0]

	svg.attr 'width', width = root.clientWidth
	svg.attr 'height', height = 400

	draw = ->

		projection = d3.geo.mercator()
		.scale 120
		.translate [width/2, height/1.7]

		path = d3.geo.path().projection projection

		svg.selectAll '.country'
		.data topojson.feature(world, world.objects.countries).features
		.enter().append 'path'
		.attr 'class', (d) -> 'country ' + d.id
		.attr 'd', path
		.on 'click', (d) -> console.log d.id

		
	if not world
		d3.json 'world.json', (err, w) -> 
			world = w
			draw()
	else 
		draw()
	
