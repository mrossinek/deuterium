# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


## [0.2] - 2020-03-22

### Added
- code cells may be used to customize execution blocks (!4)
- motion-based code selection for execution (!5)

### Changed
- `<S-CR>` no longer takes a range and instead relies on automatic selection of
    the block of code based on the indent level (f11f8b4)
- if `jump_line_after_execute` is set the cursor will jump after the end of the
    executed block of code (457e307)


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


[Unreleased]: https://gitlab.com/mrossinek/deuterium/-/compare/v0.2...master
[0.2]: https://gitlab.com/mrossinek/deuterium/-/tags/v0.2
[0.1]: https://gitlab.com/mrossinek/deuterium/-/tags/v0.1
[0.0.1]: https://gitlab.com/mrossinek/deuterium/-/tags/v0.0.1
