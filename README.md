# rubygems-credential_store-backends-codeartifact

A [credential store](https://github.com/ruby/rubygems/pull/9671) backend for RubyGems and Bundler that gets [AWS CodeArtifact](https://docs.aws.amazon.com/codeartifact/latest/ug/using-ruby.html) authorization tokens on demand.

Instead of preparing a CodeArtifact token yourself, the backend runs `aws codeartifact get-authorization-token` whenever RubyGems or Bundler needs a credential for a CodeArtifact repository. Tokens are never written anywhere. They live only in the memory of the process that asked for them.

## Requirements

- RubyGems 4.1.0 or later
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Installation

```sh
gem install rubygems-credential_store-backends-codeartifact
```

## Usage

### Bundler

Select the backend for the CodeArtifact host only, so that other hosts keep using whatever store they use now:

```sh
bundle config set --global credential_store.my-domain-111122223333.d.codeartifact.us-east-1.amazonaws.com codeartifact
```

You might also need to enable the credential store:

```sh
bundle config set credential_store true
```

Then use the repository as a source in the Gemfile:

```ruby
source "https://my-domain-111122223333.d.codeartifact.us-east-1.amazonaws.com/my_domain/ruby/" do
  gem "example"
end
```

### gem push

Select the backend in `~/.gemrc`, or for a single command with `RUBYGEMS_CREDENTIAL_STORE`:

```sh
RUBYGEMS_CREDENTIAL_STORE=codeartifact gem push --host https://my-domain-111122223333.d.codeartifact.us-east-1.amazonaws.com/my_domain/ruby my_gem-0.1.0.gem
```

## Configuration

You can switch AWS profile per CodeArtifact domain. By default the AWS CLI picks the profile as usual (`AWS_PROFILE`, then the `default` profile and the rest of its credential chain). To use a specific profile, create `$XDG_CONFIG_HOME/rubygems-credential_store-backends-codeartifact/config.yml` (or `~/.config/...` when `XDG_CONFIG_HOME` is unset):

```yaml
profile: dev-sso                 # Default profile; used for every domain without its own entry
domains:
  "arn:aws:codeartifact:us-east-1:111122223333:domain/my-domain":
    profile: shared-artifacts
```

The profile is chosen in this order:

1. The entry for the domain under `domains`
2. The top-level `profile`
3. None, leaving the choice to the AWS CLI

The configuration belongs to the user rather than to a project, because AWS profile names are personal.

## Limitations

The backend does not work while Bundler installs gems into a custom path, such as with `bundle config set path vendor/bundle` or `BUNDLE_PATH`. In that case Bundler hides the system gems, including this one, so it warns that the `codeartifact` backend is not installed and falls back to the credentials in its config files.

## Alternatives

Even without using this credential store, you can write and use a wrapper command that stores CodeArtifact credentials in environment variables.

For example, you can write the following script as `auth-codeartifact-ruby` and use it like `auth-codeartifact-ruby bundle install`.

```sh
#!/bin/bash
set -eu

token=$(aws codeartifact get-authorization-token --region us-east-1 --domain ruby --query authorizationToken --output text)
export BUNDLE_RUBY___111122223333__D__CODEARTIFACT__US___EAST___1__AMAZONAWS__COM="aws:$token"
exec "$@"
```

When using a credential store, there is a difference in that you no longer have to think about whether a wrapper command is necessary every time. On the other hand, it also has the downside of making it harder to track where permissions were used.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nekketsuuu/rubygems-credential_store-backends-codeartifact.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
