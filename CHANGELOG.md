# Change Log

## [0.7.0]
### Added
- Aptly.escape_prefix is a new helper method to turn prefixes into
  REST API format.

### Changed
- Aptly.publish and all publishing methods built on top of it now raise an
  InvalidPrefixError when they encounter a forward-slash in the publishing
  prefix. Aptly's REST API enforces prefixes to be encoded with _ as __ and
  / as _ unfortuantely as this is ambiguous we cannot automatically determine
  if a prefix is encoded or unencoded. To retain backwards compatibility the
  assumption is that is is encoded and if it clearly is not an error is raised.
  For 1.0 this expectation is changing to assume the prefix is unencoded and
  will be forcefully encoded!
