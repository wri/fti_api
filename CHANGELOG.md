# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.7] - 2017-09-28
### Backoffice
- Improved the dashboard (added pending documents and operators)
- The last filters used are saved

### Features
- Created task for expiring documents and performing the scores calculations
- Changed the certifications from being associated to an Operator, to an FMU
- Made the Required Operator Document persisted even when deleted

### Import
- Imported Operator Documents' Files

### Technical details
- Added cascade deletes to the required operator document

## [0.9.6] - 2017-09-28
### Backoffice
- Added the resources:
  - Laws
  - Species
  - FMUs
  - Monitors
- Improved usability and the interface
- Insured only admins who are active can log in
- Improved forms:
  - Observer
  - Operator
  - Observation
- Created the buttons to deploy the Portal and IM BO (and update the translations)

### Features
- Added filters and sorting in the IM BO for:
  - `Operators`
  - `Monitors`

### Technical details
- Added endpoint for severities  

## [0.9.5] - 2017-09-20
### Features
- Creation of operators in the Portal
- New fields for Operators (website and address)
- Added filters and sorting in the IM BO for:
  - `FMUs` 
  - `Observation Reports`
  - `Observation Documents`
  - `Laws` 
- Creating a report in an observation makes all the observers own the report
- Created special rules for operators with FA ID
  - Are the only ones with documents
  - Are the only ones with observation scores
  
### Technical details
- Refactored the import task



## [0.9.4] - 2017-09-13
### Imports
- New data for governance and operator observations

### Technical details
- Refactored the permissions system

### Bug fixes
- In the IM BO, only the user's monitor was being listed in the observations
- Permissions: ngo's couldn't create reports or documents

## [0.9.3] - 2017-09-6
### Technical details
- Added `created-at` and `updated-at` for observations
- Added `operator` and `monitor` to the users endpoint
- Added filter by report id to observations endpoint
- Added controller action to the JsonApi Resources context
- Removed the default scope from observations
- When creating an observation, the current monitor is added to its monitor list
- FMUs included in `observations-tool` now have the geoJason
- Added touch for observations/observers/reports/documents
- Created the task to import Laws
- Added touch to observer and observation when saving reports and documents
- Created a deploy and import task


### Improvements
- Observations tool
  - Admins can see all observations

### Additions
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