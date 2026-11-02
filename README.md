[![CI](https://github.com/BuddyandSelly/it_operations/actions/workflows/ci.yml/badge.svg)](https://github.com/BuddyandSelly/it_operations/actions/workflows/ci.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
# ItOperations
This is a feature extracted from Buddy, that was implemented in Content System and makes sense to make a gem out of it, so we can reduce code repetition and use it in different projects.

The idea behind ItOperations (formerly called ArticleItOperation) is to have a way to deal with data-transfer operations for large datasets, where we typically work around a list of entities (such as articles), and have a better overview about how the operation was (if successful; if failed, why?; don't interrupt other entities from dataset getting updated if one fails, etc).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'it_operations', github: "reverseretail/it_operations", tag: 'v0.1.0'
```

And then execute:

    $ bundle install

And run:
```ruby
rails generate it_operations:install
rails db:migrate
```

## Usage

Example:
We want to perform some action "SAMPLE_OP" on Orders with id 1, 2 and 3. And some other operation ("OTHER_OP") with the first order (1).
We could insert these operations:
```ruby
ItOperations.create_from_entity_ids([1,2,3], 'Order', 'SAMPLE_OP')
ItOperations.create_from_entity_ids([1], 'Order', 'OTHER_OP')
# this would insert the following records to the it_operations table:
{ entity_class: 'Order', operation: 'SAMPLE_OP', entity_id: 1, ... }
{ entity_class: 'Order', operation: 'SAMPLE_OP', entity_id: 2, ... }
{ entity_class: 'Order', operation: 'SAMPLE_OP', entity_id: 3, ... }
{ entity_class: 'Order', operation: 'OTHER_OP',  entity_id: 1, ... }
# the omitted values are
# successful: false, processed: false, result: nil, arguments: nil, created_at: <current datetime>, updated_at: <current datetime>
# If we'd need to add arguments to some of them, we could just update those records:
ItOperations.by_op("SAMPLE_OP").each do |op|
  op.update(arguments: "arg#{op.id}")
end
```
Then, to perfom the SAMPLE_OP, we use a block which we use to write the actual operation implementation:
```ruby
ItOperations.run("SAMPLE_OP") do |order, args|
  puts "Doing something with #{order.id} and #{args}"
end
# Should print:
# Doing something with 1 and arg1
# Doing something with 2 and arg2
# Doing something with 3 and arg3

# Checking the status for these ops:
ItOperations.by_op("SAMPLE_OP").map(&:as_json)
# output:
# { entity_class: 'Order', operation: 'SAMPLE_OP', entity_id: 1, successful: true, processed: true, result: 'done', arguments: 'arg1', created_at: <datetime when was created>, updated_at: <datetime when was executed> }
# { entity_class: 'Order', operation: 'SAMPLE_OP', entity_id: 2, successful: true, processed: true, result: 'done', arguments: 'arg2', created_at: <datetime when was created>, updated_at: <datetime when was executed> }
# { entity_class: 'Order', operation: 'SAMPLE_OP', entity_id: 3, successful: true, processed: true, result: 'done', arguments: 'arg3', created_at: <datetime when was created>, updated_at: <datetime when was executed> }
```
When an operation fails:
```ruby
ItOperations.run("OTHER_OP") do
  raise "some error message"
end
ItOperations.by_op("OTHER_OP").map(&:as_json)
# => { entity_class: 'Order', operation: 'OTHER_OP', entity_id: 1, successful: false, processed: true, result: 'some error message', arguments: nil, created_at: <datetime when was created>, updated_at: <datetime when was executed> }
```

## Development

The gem is developed and tested against the Ruby version in [.ruby-version](.ruby-version) and
supports Ruby >= 3.2 with Rails >= 7.0.

```bash
bundle install
bundle exec rspec    # specs, including the coverage check
bundle exec rubocop  # style
bundle exec rake     # both of the above
```

The specs run against an in-memory sqlite database, and each one is wrapped in a transaction that is
rolled back afterwards. They are measured with
[SimpleCov](https://github.com/simplecov-ruby/simplecov): line and branch coverage of everything in
`lib/` have to stay at 100%, and the suite fails otherwise. The HTML report is written to
`coverage/index.html`, and CI comments both percentages on every pull request.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/it_operations. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/it_operations/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the ItOperations project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/it_operations/blob/master/CODE_OF_CONDUCT.md).
