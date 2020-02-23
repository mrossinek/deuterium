# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


## [0.1] - 2020-02-23

### Added
- ensure cleaner shutdown through use of KernelManager (81240935)
- improve user configurability
- add vim documentation
- trigger `+` at the end of `DeuteriumExecute` (37297755)
- clear virtual text on all lines that are executed (8b87886e)
- unittests and Gitlab CI (!2)

### Changed
- split `DeuteriumSend` into an execute and internal send function (d248dbd)
- the above renames all `send`-related names (visible to the user) to `execute`
- longer outputs on stdout and stderr streams can be handled in either popup or
    preview windows (configured via `handler` settings) (!1)


## [0.0.1] - 2020-02-10

### Added
- initial version with basic functionality


[Unreleased]: https://gitlab.com/mrossinek/deuterium/-/compare/v0.0.1...master
[0.0.1]: https://gitlab.com/mrossinek/deuterium/-/tags/v0.0.1
