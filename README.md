# Perform

A simple way to use the Railway Pattern in ruby. 


Inspired by looking at the `light-service` gem and seeing it's use of the 
Railway Pattern and validating actions inputs and outputs as a good idea, 
only it's implementation seemed overly complicated. 

I wanted to create a lib that:

* Is simple with no dependencies
* Has no boilerplate or Action sub-classes
* Has no DSL or dealing directly with a context object 
* Can use Plain Old Ruby Objects and Lambdas as actions
* But still supports the Railway Pattern and input/output validation

## Comparision

For comparison, here is an example of a basic `light-service` action:

```ruby
class Foo
  extend LightService::Action       # Every action must extend LightService, no POROs
  expects :a                        # DSL required
  promises :b

  executed do |context|
    context.b = context.a + 1       # must use context instead of normal ruby params
    context.fail!('Its over 9000!') if context.b > 9000
  end
end

class Bar
  extend LightService::Action       # Even simple actions require a lot of boiler plate
  expects :a, :b

  executed do |context|
    "#{context.a} #{context.b}"
  end
end

extend LightService::Organizer

with(a: 1).reduce(                  # Hard to see what params are required
  Foo,                              # or what Actions will return
  Bar                           
)
```

Using `with` takes `{a: 1}` as it's initial context and is passed to `Foo` 
who sets `:b` in the context. Then both `:a` and `:b` are passed into 
`Bar`. But you can't see that without jumping into the Action classes.

See more examples in `examples/light_services`.


Now here is the example in `Perform`.

```ruby
class Foo                           # Any PORO class with `call` be an action
  def self.call(a:)                 # Uses ruby's built in named parameters
    b = a + 1
    b > 9000 ?
      Failure('Its over 9000!') :   # Must return a `Result` class or you
      Success(b)                    # must wrap it in `successful` when 
  end                               # calling perform
end

Bar = ->(a:, b:) { "#{a} #{b}" }    # Lambda can be an action

include Perform::Module

perform(
  {a: 1},
  [Foo, [:a] => :b],                # Easy to see required params and return keys
  [Bar, [:a, :b]]
)
```

A basic action in `Perform` can be any object that has a call method. 
It should return a `Success` or `Failure` result. If your action does not
return a `Result`, you can wrap the action with `successful` to have it 
always return a `Success` if the action returns nothing or only a value. 

## Usage

### Pipe-like Syntax

Pipe a context into a series of actions that can expect parameters and promise return values.

```ruby
perform(
  {a: 1},
  [Foo, [:a] => :b ],
  [successful(DontCareAboutReturnValue), [:b]],
  [Bar, [:a, :b]]
)
```

First line sets the initial context `{a: 1}` 
Second line defines a callable and promises to pass it `:a` from the context
and expects it to return a value for `:a`.

If an expected value is not available in the context, an `ArgumentError` 
for the missing key will be raised.

If a promised value is not returned, a `ResultError` will be raised for the missing return-key.

If at any point a `Failure` is returned from an action, 
the next action will not be run and the failure will be returned.

The entire context will be available in `Result` value on success or failure. 
The error can be found in `result.value[:error]`.

### Do-notation-like syntax

Inspired from F# and Haskell do-notation.

```ruby
perform do 
  a = unwrap FetchAValue.call
  b = unwrap Foo.call(a)
  DontCareAboutReturnValue(b)
  Bar(a, b)
end
```

The first line calls `Foo` and unwraps it's `Result` into `a`.
If the `Result` is a `Failure`, unwrap will stop execution and the failure will be returned.

There's no need to unwrap the last statement. Perform will check for a failure, and it will wrap the
final result in a Success if it's just a value.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'perform'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install perform

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dereckrx/perform.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
