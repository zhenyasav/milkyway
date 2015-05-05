class @App

	@min:
		scale: 1
		size: 0

	@max:
		scale: 150
		size: 1

	constructor: (o) ->
		_.extend @, o

	savePending: ->
		throw "app has no _id" if not @_id

		return if not @pending?.availability?

		Apps.update @_id,
			$set:
				availability: @pending.availability
			$unset:
				pending: ''

	discardPending: ->
		throw "app has no _id" if not @_id

		return if not @pending?.availability?

		Apps.update @_id,
			$unset:
				pending: ''

	setAvailabilitySize: (zoneName, size) ->
		throw "app has no _id" if not @_id

		return if not @pending?.availability?

		zone = _.find @pending.availability ? [], (a) -> a.name is zoneName
		throw "setsize: no such zone" if not zone

		throw "setsize: size out of range" if size not in [0, 1]
		
		zone.size = size

		Apps.update @_id,
			$set:
				'pending.availability': @pending.availability

	setAvailabilityScale: (zoneName, scale) ->
		throw "app has no _id" if not @_id

		return if not @pending?.availability?

		zone = _.find @pending.availability ? [], (a) -> a.name is zoneName
		throw "setscale: no such zone" if not zone

		throw "setscale: scale out of range" if not (App.min.scale <= scale <= App.max.scale)

		zone.scale = scale

		Apps.update @_id,
			$set:
				'pending.availability': @pending.availability

	removeAvailability: (zone) ->
		throw "app has no _id" if not @_id
		throw "no zone" if not zone

		return if not @pending? and not _.find(@availability ? [], (a) -> a.name is zone)

		return if @pending? and not _.find(@pending?.availability ? [], (a) -> a.name is zone)

		if not @pending?.availability?
			@pending = availability: _.clone @availability
			Apps.update @_id,
				$set:
					'pending.availability': @pending
				
		@pending.availability = _.reject @pending.availability, (a) -> a.name is zone
		Apps.update @_id,
			$set: 
				'pending.availability': @pending.availability

	addAvailability: (zone) ->
		throw "app has no _id" if not @_id
		throw "no zone" if not zone
		
		return if not @pending? and _.find(@availability ? [], (a) -> a.name is zone)
		return if @pending? and _.find(@pending?.availability ? [], (a) -> a.name is zone)

		if not @pending?.availability?
			Apps.update @_id,
				$set:
					'pending.availability': @availability

		Apps.update @_id,
			$push:
				'pending.availability': 
					name: zone
					size: 0
					scale: 1
