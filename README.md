# heroku2dokku

Heroku -> Dokku in minutes

## Installation

*You should already have Dokku set up on a server - see [this guide](https://github.com/ankane/shorts/blob/master/Dokku-Digital-Ocean.md) for instructions for DigitalOcean*

Install the official Dokku client

```sh
git clone git@github.com:progrium/dokku.git ~/.dokku

# add the following to either your
# .bashrc, .bash_profile, or .profile file
alias dokku='$HOME/.dokku/contrib/dokku_client.sh'
```

And run:

```sh
gem install heroku2dokku
```

## How to Use

In your app directory, run:

```sh
git remote add dokku dokku@dokkuhost:myapp
heroku2dokku all
```

This:

1. creates app
2. copies config
3. copies custom domains
3. adds a [CHECKS file](http://progrium.viewdocs.io/dokku/checks-examples.md) for zero-downtime deploys

Commit the `CHECKS` file and deploy away!

```sh
git add CHECKS
git commit -m "Added checks"
git push dokku master
```

## Database

To transfer your database, export your data

```sh
heroku maintenance:on
heroku pg:backups capture
curl -o latest.dump `heroku pg:backups public-url`
```

Import to a new database

```sh
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U myuser -d mydb latest.dump
```

And update your config

```
dokku config:set DATABASE_URL=postgres://...
```

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/heroku2dokku/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/heroku2dokku/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/heroku2dokku.git
cd heroku2dokku
bundle install
bundle exec rake test
```
