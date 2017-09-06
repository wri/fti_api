# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.3] - 2017-09-6
### Technical details
- Added `created-at` and `updated-at` for observations
- Added `operator` and `monitor` to the users endpoint
- Added filter by report id to observations endpoint
- Added controller action to the JsonApi Resources context
- Removed the default scope from observations
- When creating an observation, the current monitor is added to its monitor list
- Fmus included in `observations-tool` now have the geoJason
- Added touch for observations/observers/reports/documents


### Improvements
- Observations tool
  - Admins can see all observations

### Aditions
- Reports can be shared between monitors
- Added `actions-taken` to observations
- Observations save the user who last modified them
- Laws

### Backoffice
- Showing all the fields in observations
- Added Miscelaneous

## [0.9.2] - 2017-09-01
### Technical details
- Changed documents to observation documents
- Added Reports to Observations

## [0.9.2] - 2017-08-31
### Technical details
- Fixed generation of api keys for users
- Deletes previous pending operator documents
- Added the app name to the context

### Fixes
- Observations tool
  - The monitors observations are now displayed (even if they haven't yet been approved)

## [0.9.1] - 2017-08-30
### Additions
- New Relic (for performance monitoring)
### Improvements
- Backoffice:
  - Sort observations by user, by fmu, by observer
  - Edit required operator documents
  - Ordering of countries listings
  - Editing observations' subcategories
  - After approving/rejecting an observation, it redirects to the same page
  - Added more information to the listing of the operator documents
  - Set user id when creating a document
  - Show old documents in the chronological view

## [0.9.0] - 2017-08-22
### Additions
- Added multiple monitors per observation
  - Changed the data import to split the monitors and import them all
  - Changed BackOffice to account for multiple monitors

## [0.9.0] - 2017-08-21
### Additions
- Changes to backoffice after the meeting of 17/08 including:
  - Added sort and filters for Operators, Observations and Documents
  - Added `approve` and `reject` actions for operator document
  - Added the monitor to the observations listing
  - Show deleted documents
- Structural changes:
  - Added Forest Atlas UUID to operators
  - Observations not approved aren't shown or used for calculations
  - Added `uploaded_by` to Operator Documents