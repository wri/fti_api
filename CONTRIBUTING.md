# Contributing
In the spirit of [free software][free-sw], **everyone** is encouraged to help improve this project.

[free-sw]: http://www.fsf.org/licensing/essays/free-sw.html

[issues]: https://github.com/vizzuality/fti_api/issues

## Submitting an Issue
We use the [GitHub issue tracker][issues] to track bugs and features. Before
submitting a bug report or feature request, check to make sure it hasn't
already been submitted. When submitting a bug report, please include a [Gist][gist]
that includes a stack trace and any details that may be necessary to reproduce
the bug, including your gem version, Ruby version, and operating system.
Ideally, a bug report should include a pull request with failing specs.

[gist]: https://gist.github.com/

## General before creating a pull request

- [A well written commit message](http://karma-runner.github.io/0.8/dev/git-commit-msg.html)
- Test suite runs!
- Necessary tests for all new features and fixes.
- No n+1 queries
- New gem installed: the gem and is added to `Gemfile` and `Gemfile.lock` (via `bundle install`)
- Code does not contain any debug statements (e.g. `byebug`, `inspect`, etc.)

## Specific cases

### Specs & Features

- The specs are in the correct place
- Specs and features do not only test the "happy path"
- Use global step definitions for features
- New spec's filename ends on `_spec.rb`
- New feature's filename ends on `.feature`
- New feature's step definition filename ends on `_steps.rb`

### Models

- Have all new associations
- An association needs a dependent attribute?
- Have meaningful validations
- Indexes on table columns when useful
- Seed data in `db/seeds.rb` if necessary

### Controllers

- Use a scope in model. Do not interact with model attributes directly
