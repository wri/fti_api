# OPEN TIMBER PORTAL API #

[![Build Status](https://travis-ci.org/Vizzuality/fti_api.svg?branch=master)](https://travis-ci.org/Vizzuality/fti_api) [![Code Climate](https://codeclimate.com/github/Vizzuality/fti_api/badges/gpa.svg)](https://codeclimate.com/github/Vizzuality/fti_api)

## DOCUMENTATION ##

[API Documentation](https://fti-api-documentation.herokuapp.com)

## USAGE ##

  Start by checking out the project from github

```
git clone https://github.com/Vizzuality/fti_api.git
cd fti_api
```

  You can either run the application natively, or inside a docker container.

## USING DOCKER ##

### REQUIREMENTS FOR DOCKER ###

  If You are going to use containers, You will need:

- [Docker](https://www.docker.com/)
- [docker-compose](https://docs.docker.com/compose/)

### RUNNING DB IN DOCKER ###

PostgreSQL database with PostGIS will run on standard 5432 port, so make sure it's not already taken.

Do not forget to setup those env variables for the database

```
POSTGRES_PORT_5432_TCP_ADDR=localhost
POSTGRES_USER=postgres
```

And run container

```
docker-compose up
```

## NATIVELY ##

### REQUIREMENTS ###

  - **Ruby version:** 2.4.6
  - **PostgreSQL 12.1+** [How to install](http://exponential.io/blog/2015/02/21/install-postgresql-on-mac-os-x-via-brew/)

**Just execute the script file in `bin/setup`**

  Depends on OPEN TIMBER PORTAL [repository](https://github.com/Vizzuality/fti_api)

**or install the dependencies manually:**

### Install global dependencies: ###

    gem install bundler

### Install gems: ###

    bundle install

### Set up the database ###

    cp config/database.yml.sample config/database.yml
    cp env.sample .env

    bundle exec rake db:create
    bundle exec rake db:schema:load

### Load sample data: ###

    bundle exec rake db:seed

### Run application: ###

    bin/rails s

## TEST ##

  To run the tests on docker:

```
./service test
```

  Run rspec:

```ruby
  bin/rspec
```

## DOCUMENTATION ##

### API ###

The API is documented used swagger and can be found in `/docs`.

To regenerate the api documentation run:

```ruby
  rails docs:generate
```

## DEPLOYMENT ##

**To deploy the API to staging environment, just execute: cap staging deploy**

## TASKS ##

**There are two tasks that should be executed in the server, with a cron job. Below there0s a suggestion on how to set up the jobs:**

```
* */8 * * * sleep $(( RANDOM \% 1000 )); cd ~/fti-api-development/current; RAILS_ENV=staging bundle exec rails scheduler:expire
* 0 * * * sleep $(( RANDOM \% 10000 )); cd ~/fti-api-development/current; RAILS_ENV=staging bundle exec rails scheduler:expire

```

## CONTRIBUTING ##

### BEFORE CREATING A PULL REQUEST ###

Please check all of [these points](https://github.com/Vizzuality/fti_api/blob/master/CONTRIBUTING.md).

1. Fork it!
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request :D
