# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] - 2017-08-21
### Added
- Changes to backoffice after the meeting of Thursday including:
  - Added sort and filters for Operators, Observations and Documents
  - Added `approve` and `reject` actions for operator document
  - Added the monitor to the observations listing
  - Show deleted documents
- Structural changes:
  - Added Forest Atlas UUID to operators
  - Observations not approved aren't shown or used for calculations
  - Added `uploaded_by` to Operator Documents