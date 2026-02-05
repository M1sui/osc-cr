# osc-cr

TODO: Write a description here

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     osc-cr:
       github: M1sui/osc-cr
   ```

2. Run `shards install`

## Usage
See `your-project/lib/example/OSC-Example.cr` for details.

```crystal
# The order must follow the sequence of each section.
# 1. Initialization
require "osc-cr"
osc = OSC.new("127.0.0.1", 9000, 9001)

# 2. Receive event
# Can be omitted if no receive processing is needed.
# `path:` is optional, but be careful: omitting it means receiving all messages.
osc.message(path: "/test/aba") { |event|
	event.data      #-> OSC argument - Value
	event.data.path #-> OSC Message - "/test/aba"
	event.data.type #-> Bool | Int32 | Float32 | String | Nil
}

# 3. Start receive server
# Can be omitted only if step 2 is omitted.
osc.run()

# 4. Other processing / main loop
osc.sendb("/test/hoge", true) # -> Bool
osc.sendi("/test/fuga", 123)  # -> Int
osc.sendf("/test/piyo", 1.23) # -> Float

loop {
  osc.sendi("/test/minute", Time.local.minute)
}
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/osc-cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [InstanceMethod](https://github.com/your-github-user) - creator and maintainer
