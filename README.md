# OPEN TIMBER PORTAL API #

## DOCUMENTATION ##

[API Documentation](https://fti-api-documentation.herokuapp.com)

## USAGE ##

  Start by checking out the project from github

```
git clone https://github.com/wri/fti_api.git
cd fti_api
```

  You can either run the application natively, or inside a docker container.

## USING DOCKER ##

### REQUIREMENTS FOR DOCKER ###

  If You are going to use containers, You will need:

- [Docker](https://www.docker.com/)
- [docker-compose](https://docs.docker.com/compose/)

### RUNNING SERVICES IN DOCKER ###

#### POSTGRES

PostgreSQL database with PostGIS will run by default on standard 5432 port. You can change it with `POSTGRES_PORT` env variable.

Here are example settings for `.env` file:

```
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres

# optional
POSTGRES_PASSWORD=postgres
POSTGRES_DATABASE=otp_database
```

And run container

```
docker-compose up -d db
```

#### REDIS

Redis will run by default on standard 6379 port. You can change it with `REDIS_PORT` env variable. You can also change the URL with `REDIS_URL` env variable.

Here are example settings for `.env` file:

```
REDIS_PORT=6380
REDIS_URL="redis://localhost:${REDIS_PORT}/0"
```

And run container

```
docker-compose up -d redis
```

We are using sidekiq for background jobs. You can run it with:

```
bundle exec sidekiq
```

Or better to run all mentioned services along with application with simply

```
bin/dev
```

## NATIVELY ##

### REQUIREMENTS ###

  - **Ruby version:** 3.2.3
  - **PostgreSQL 12.1+** [How to install](http://exponential.io/blog/2015/02/21/install-postgresql-on-mac-os-x-via-brew/)

**Just execute the script file in `bin/setup`**

  Depends on OPEN TIMBER PORTAL [repository](https://github.com/wri/fti_api)

**or install the dependencies manually:**

### Install global dependencies: ###

    gem install bundler

### Install gems: ###

    bundle install

### Set up the database ###

    cp env.sample .env

    bundle exec rake db:create
    bundle exec rake db:schema:load

### Load sample data: ###

    bundle exec rake db:seed

### Run all development services: ###

    bin/dev

### Run only selected services: ###

    bin/dev -m "redis=1,db=1,sidekiq=1"

### Load remote database locally

Project is using [capistrano-db-tasks](https://github.com/sgruhier/capistrano-db-tasks) gem to load remote database locally.

There are also couple rake tasks to help with that:

To download compressed remote database dump to local machine and keep it in `db/dumps` directory:

```
bin/rails db:download [SERVER=production(default)|staging] [SMALL=1]
```

To restore local database from the dump file:

```
bin/rails db:restore_from_file [FILE=db/dumps/example.sql[.gz]]
```
FILE is optional, by default it loads latest dump file by modification time.

To restore DB from the server without keeping the downloaded dump file:

```
bin/rails db:restore_from_server [SERVER=production(default)|staging] [SMALL=1]
```

## TEST ##

Run rspec:

```ruby
bundle exec rspec
```

## DOCUMENTATION ##

### API ###

The API is documented used swagger and can be found in `/docs`.

To regenerate the api documentation run:

```ruby
bin/rails docs:generate
```

## DEPLOYMENT ##

Deploy to production with `cap production deploy` it will deploy the `master` branch.

To deploy the API to staging environment use `cap staging deploy`, by default that will deploy `staging` branch, but you can change it with `BRANCH` env variable (ex. `cap staging deploy BRANCH=develop`)

After deployment crontab will be automatically updated with the new cron jobs. (check config/schedule.rb for more details)

## CONTRIBUTING ##

### BEFORE CREATING A PULL REQUEST ###

Please check all of [these points](https://github.com/wri/fti_api/blob/master/CONTRIBUTING.md).

1. Fork it!
2. Create your feature branch: `git checkout -b feature/my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/my-new-feature`
5. Submit a pull request :D
