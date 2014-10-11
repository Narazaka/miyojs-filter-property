chai = require 'chai'
chai.should()
expect = chai.expect
sinon = require 'sinon'
MiyoFilters = require '../property.js'

describe 'initialize', ->
	ms = null
	request = null
	id = null
	stash = null
	beforeEach ->
		ms = sinon.stub()
		ms.call_entry = sinon.stub()
		request = sinon.stub()
		id = 'OnTest'
		stash = null
	it 'should define methods', ->
		argument =
			property_initialize:
				handlers: ['coffee', 'jse', 'js']
		return_argument = MiyoFilters.property_initialize.call ms, argument, request, id, stash
		return_argument.should.be.deep.equal argument
		ms.should.have.property 'property'
		ms.property.should.be.instanceof Function
		ms.should.have.property 'has_property'
		ms.has_property.should.be.instanceof Function
		ms.should.have.property 'set_compiled_property'
		ms.set_compiled_property.should.be.instanceof Function
		ms.should.have.property 'compiled_property'
		ms.compiled_property.should.be.instanceof Function

describe 'property call', ->
	ms = null
	request = null
	id = null
	stash = null
	filter = MiyoFilters.property
	argument = null
	beforeEach ->
		ms = sinon.stub()
		ms.filters =
			property_handler: MiyoFilters.property_handler
		request = sinon.stub()
		id = 'OnTest'
		stash = null
		argument =
			'ok': 'plain'
			'plain': 'plain'
			'ok.js': '''
				ret = "js";
				return [ret, request, id, stash]
			'''
			'compile_error.js': '''
				js -=
			'''
			'runtime_error.js': '''
				js
			'''
			'ng.jse': '''
				j = "j";
				ret = "jse";
				[ret, request, id, stash]
			'''
			'ok.jse': '["jse", request, id, stash]'
			'ok.coffee': '''
				ret = "coffee"
				[ret, request, id, stash]
			'''
			'block.coffee': '''
				ret = "coffee"
				a = null
				if a?
					1
				else
					[ret, request, id, stash]
			'''
			'skip.js': 'return "js"'
	it 'should work with plain', ->
		initialize_argument =
			property_initialize:
				handlers: []
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		property = ms.property argument, 'ok', request, id, stash
		property.should.be.equal 'plain'
	it 'should work with js', ->
		initialize_argument =
			property_initialize:
				handlers: ['js']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		property = ms.property argument, 'ok', request, id, stash
		property.should.be.deep.equal ['js', request, id, stash]
	it 'should fail with compile error js', ->
		initialize_argument =
			property_initialize:
				handlers: ['js']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		(-> ms.property argument, 'compile_error', request, id, stash).should.throw /property compile error/
	it 'should fail with runtime error js', ->
		initialize_argument =
			property_initialize:
				handlers: ['js']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		(-> ms.property argument, 'runtime_error', request, id, stash).should.throw /property execute error/
	it 'should work with jse', ->
		initialize_argument =
			property_initialize:
				handlers: ['jse']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		property = ms.property argument, 'ok', request, id, stash
		property.should.be.deep.equal ['jse', request, id, stash]
	it 'should work with miss jse', ->
		initialize_argument =
			property_initialize:
				handlers: ['jse']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		property = ms.property argument, 'ng', request, id, stash
		property.should.be.equal 'j'
	it 'should work with coffee', ->
		initialize_argument =
			property_initialize:
				handlers: ['coffee']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		property = ms.property argument, 'ok', request, id, stash
		property.should.be.deep.equal ['coffee', request, id, stash]
	it 'should work with coffee block', ->
		initialize_argument =
			property_initialize:
				handlers: ['coffee']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		property = ms.property argument, 'block', request, id, stash
		property.should.be.deep.equal ['coffee', request, id, stash]
	it 'should take handler in order', ->
		initialize_argument =
			property_initialize:
				handlers: ['coffee', 'js']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		property = ms.property argument, 'ok', request, id, stash
		property.should.be.deep.equal ['coffee', request, id, stash]
		property = ms.property argument, 'skip', request, id, stash
		property.should.be.deep.equal 'js'
		property = ms.property argument, 'plain', request, id, stash
		property.should.be.deep.equal 'plain'
	it 'should return undefined on not exists', ->
		initialize_argument =
			property_initialize:
				handlers: []
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		property = ms.property argument, 'dummy', request, id, stash
		expect(property).is.undefined
	it 'should work with compiled', ->
		initialize_argument =
			property_initialize:
				handlers: []
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		property = ms.property argument, 'ok', request, id, stash
		property.should.be.equal 'plain'
		property = ms.property argument, 'ok', request, id, stash
		property.should.be.equal 'plain'
	it 'should process pre hook object', ->
		initialize_argument =
			property_initialize:
				handlers: []
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		pre_hook_handler = (property, request, id, stash) -> Object.keys(@filters).length + property + id
		property = ms.property argument, 'ok', request, id, stash, 'plain': pre_hook_handler
		property.should.be.equal Object.keys(ms.filters).length + 'plain' + id
	it 'should process pre hook single', ->
		initialize_argument =
			property_initialize:
				handlers: []
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		pre_hook_handler = (property, request, id, stash) -> Object.keys(@filters).length + property + id
		property = ms.property argument, 'ok', request, id, stash, pre_hook_handler
		property.should.be.equal Object.keys(ms.filters).length + 'plain' + id
	it 'should not process pre hook not match', ->
		initialize_argument =
			property_initialize:
				handlers: ['js']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		pre_hook_handler = (property, request, id, stash) -> 'dummy'
		property = ms.property argument, 'skip', request, id, stash, 'plain': pre_hook_handler
		property.should.be.equal 'js'
	it 'should process pre hook function with attributes', ->
		initialize_argument =
			property_initialize:
				handlers: ['jse', 'js']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		pre_hook = (property, request, id, stash) -> Object.keys(@filters).length + property + id
		pre_hook.jse = (property, request, id, stash) -> "'" + Object.keys(@filters).length + property + id + 'jse' + "'"
		property = ms.property argument, 'ok', request, id, stash, pre_hook
		property.should.be.equal Object.keys(ms.filters).length + argument['ok.jse'] + id + 'jse'
		property = ms.property argument, 'plain', request, id, stash, pre_hook
		property.should.be.equal Object.keys(ms.filters).length + 'plain' + id
	it 'should fail with pre hook error', ->
		initialize_argument =
			property_initialize:
				handlers: []
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		pre_hook_handler = (property, request, id, stash) -> a
		(-> ms.property argument, 'ok', request, id, stash, pre_hook_handler).should.throw /property pre_hook execute error/

describe 'has_property call', ->
	ms = null
	request = null
	id = null
	stash = null
	filter = MiyoFilters.property
	argument = null
	beforeEach ->
		ms = sinon.stub()
		ms.filters =
			property_handler: MiyoFilters.property_handler
		request = sinon.stub()
		id = 'OnTest'
		stash = null
		argument =
			'all': 'plain'
			'all.js': '''
				ret = "js";
				return [ret, request, id, stash]
			'''
			'all.jse': '["jse", request, id, stash]'
			'all.coffee': '''
				ret = "coffee"
				[ret, request, id, stash]
			'''
			'jse.jse': '"jse"'
			'js.js': 'return "js"'
			'coffee.coffee': '"coffee"'
			'plain': 'plain'
	it 'should work with no handlers', ->
		initialize_argument =
			property_initialize:
				handlers: []
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		ms.has_property(argument, 'all').should.be.true
		ms.has_property(argument, 'plain').should.be.true
		ms.has_property(argument, 'coffee').should.be.false
	it 'should work with handlers', ->
		initialize_argument =
			property_initialize:
				handlers: ['js', 'coffee']
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		ms.has_property(argument, 'all').should.be.true
		ms.has_property(argument, 'plain').should.be.true
		ms.has_property(argument, 'coffee').should.be.true
		ms.has_property(argument, 'js').should.be.true
		ms.has_property(argument, 'jse').should.be.false
	it 'should work with compiled', ->
		initialize_argument =
			property_initialize:
				handlers: []
		MiyoFilters.property_initialize.call ms, initialize_argument, request, id, stash
		ms.property argument, 'plain', request, id, stash
		ms.has_property(argument, 'plain').should.be.true
		ms.property argument, 'dummy', request, id, stash
		ms.has_property(argument, 'dummy').should.be.false
