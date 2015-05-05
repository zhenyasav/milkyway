
class @App

	@min:
		scale: 1
		size: 0

	@max:
		scale: 150
		size: 1

	@pricing: [0.05, 0.1]

	@monthlyEstimate: (availability) ->
		_.reduce availability ? [], (m, n) ->
			m + App.zoneEstimate n
		, 0

	@zoneEstimate: (zone) ->
		if price = App.pricing[zone.size]
			if scale = zone.scale
				price * scale * 24 * 30
		else
			0

	constructor: (o) ->
		_.extend @, o

	savePending: (prop) ->
		throw "app has no _id" if not @_id

		return if not @pending?[prop]?

		setter = {}
		setter[prop] = @pending[prop]

		unsetter = {}
		unsetter["pending.#{prop}"] = ''
		if @pending?[prop]?
			delete @pending[prop]

		Apps.update @_id,
			$set: setter
			$unset: unsetter

	discardPending: (prop) ->
		throw "app has no _id" if not @_id
		
		return if not @pending?[prop]?

		unsetter = {}
		unsetter["pending.#{prop}"] = ''
		if @pending?[prop]?
			delete @pending[prop]

		Apps.update @_id,
			$unset: unsetter

	setConfig: (code) ->
		throw "app has no _id" if not @_id

		return if code is @config

		if not @pending?.config
			@pending = _.extend @pending ? {}, config: @config
			Apps.update @_id,
				$set:
					'pending.config': @config

		@pending.config = code

		Apps.update @_id,
			$set:
				'pending.config': code


	setAvailabilitySize: (zoneName, size) ->
		throw "app has no _id" if not @_id

		if not @pending?.availability?
			if _.find(@availability ? [], (a) -> a.name is zoneName)
				@pending = _.extend @pending ? {}, availability: _.clone @availability
				Apps.update @_id,
					$set:
						'pending.availability': @availability

		zone = _.find @pending.availability ? [], (a) -> a.name is zoneName
		throw "setsize: no such zone" if not zone

		throw "setsize: size out of range" if size not in [0, 1]
		
		zone.size = size

		Apps.update @_id,
			$set:
				'pending.availability': @pending.availability

	setAvailabilityScale: (zoneName, scale) ->
		throw "app has no _id" if not @_id

		if not @pending?.availability?
			if _.find(@availability ? [], (a) -> a.name is zoneName)
				@pending = _.extend @pending ? {}, availability: _.clone @availability
				Apps.update @_id,
					$set:
						'pending.availability': @availability

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
			@pending = _.extend @pending ? {}, availability: _.clone @availability
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
			@pending = _.extend @pending ? {}, availability: _.clone @availability
			Apps.update @_id,
				$set:
					'pending.availability': @availability

		Apps.update @_id,
			$push:
				'pending.availability': 
					name: zone
					size: 0
					scale: 1


