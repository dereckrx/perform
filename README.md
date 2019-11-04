# Perform

Inspired by looking at the `light-service` gem and seeing it's use of the 
Railway Pattern and validating actions inputs and outputs as a good idea, 
only it's implementation seemed overly complicated. 

See examples in `examples/light_services`.


I wanted to create a lib that:

* Is simple with no dependencies
* Has no boilerplate or Action sub-classes
* Has no DSL or dealing directly with a context object 
* Can use Plain Old Ruby Objects and Lambdas as actions
* But still supports the Railway Pattern and input/output validation

`Perform` is what I came up with.

## Usage

### Pipe-like Syntax

Pipe a context into a series of actions that can expect parameters and promise return values.

```ruby
perform(
  {a: 1},
  [Bar, [:a] => :b ],
  [successful(DontCareAboutReturnValue), [:b]],
  [Baz, [:a, :b]]
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

Inspired from F# and Haskel do-notation.

```ruby
perform do 
  a = unwrap Foo.call(1)
  b = unwrap Bar.call(a)
  DontCareAboutReturnValue(b)
  Baz(a, b)
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
