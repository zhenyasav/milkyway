class @App

	@min:
		scale: 1

	@max:
		scale: 150

	constructor: (o) ->
		_.extend @, o



	setAvailabilitySize: (zoneName, size) ->
		throw "app has no _id" if not @_id

		zone = _.find @availability ? [], (a) -> a.name is zoneName
		throw "setsize: no such zone" if not zone

		throw "setsize: size out of range" if size not in [0, 1]
		
		zone.size = size

		Apps.update @_id,
			$set:
				availability: @availability

	setAvailabilityScale: (zoneName, scale) ->
		throw "app has no _id" if not @_id

		zone = _.find @availability ? [], (a) -> a.name is zoneName
		throw "setscale: no such zone" if not zone

		throw "setscale: scale out of range" if not (App.min.scale <= scale <= App.max.scale)

		zone.scale = scale

		Apps.update @_id,
			$set:
				availability: @availability

	removeAvailability: (zone) ->
		throw "app has no _id" if not @_id
		throw "no zone" if not zone

		if _.find(@availability ? [], (a) -> a.name is zone)
			@availability = _.reject @availability, (a) -> a.name is zone
			Apps.update @_id,
				$set: {@availability}

	addAvailability: (zone) ->
		throw "app has no _id" if not @_id
		throw "no zone" if not zone
		
		if not _.find(@availability ? [], (a) -> a.name is zone)

			Apps.update @_id,
				$push:
					availability: 
						name: zone
						size: 0
						scale: 1
