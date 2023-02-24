# crystal-mime

Adding support for RAW mime email parsing.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     crystal-mime:
       github: aluminumio/crystal-mime
   ```

2. Run `shards install`

## Usage

```crystal
require "crystal-mime"

email = MIME.mail_object_from_raw(raw_email_mime)
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/aluminumio/crystal-mime/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jonathan Siegel](https://github.com/usiegj00) - creator and maintainer
