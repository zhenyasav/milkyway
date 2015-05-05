Billing = AppRoute.extend

	template: 'billing'

Router.route '/apps/:id/billing', controller: Billing

currencyFormat = '0,0.00'

Template.billing.helpers

	billProgress: ->
		day = moment().date()
		days = moment().daysInMonth()
		prog = day / days

	current: ->
		day = moment().date()
		days = moment().daysInMonth()
		prog = day / days
		last = App.monthlyEstimate @availability

		numeral(prog * last).format currencyFormat

	percent: ->
		day = moment().date()
		days = moment().daysInMonth()
		prog = day / days
		numeral(prog * 100).format '0'

	last: ->

		numeral(App.monthlyEstimate @availability).format currencyFormat
