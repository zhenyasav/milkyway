if Meteor.isClient

	@Apps = new Mongo.Collection null,
		transform: (o) -> new App o

	@Traffic = new Mongo.Collection null

	


