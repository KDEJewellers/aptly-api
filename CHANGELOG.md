# Change Log

## [0.9.1]
### Fixed
- Hint at needing `noRemove: 1` as param when loop adding files (default
  behavior is to remove added files) in the `Files.tmp_upload` documentation.
- `Connection` properly passes query parameters for post-ish requests now.
- `Repository.add_file` no longer mangles it's query parameters as they are
  inconsistently cased on the API level.

## [0.9.0]
### Added
- `Files.tmp_upload` is a new convenience wrapper around `#upload` and
  `#delete`. It picks a temporary directory name and uploads the list of files
  to that directory, it then yields the directory name so you can use it as file
  identifier for the files. When the method returns it automatically cleans the
  remote up via `#delete`.

### Changed
- `Repository.upload` is now based on `Files.tmp_upload`. Functionally
  all remains the same; the temporary directory name on the remote changes.
- Temporary directory names now include a thread id to reduce the risk of
  conflicts across different threads.

## [0.8.2]
### Fixed
- Temporary files no longer contain characters that trip up the daemon.

## [0.8.1]
### Changed
- Ruby 2.5.0 compatible. Temporary name construction of uploaded files now
  happens using a custom helper instead of relying on tmpdir internals.

## [0.8.0]
### Added
- Configuration now has two new attributes timeout and write_timeout.
  When you set a timeout manually on the Aptly configuration object it gets
  used even if you have global timeouts set elsewhere.
  As a side effect setting timeouts on faraday directly will not work anymore.
  If you used to set a faraday-wide timeout we will try to use it,
  iff longer than our default value. So, the effective default is at least
  15 minutes but may be longer depending on the Faraday timeout.
  This Faraday fallback is getting removed in 1.0, so you should port
  to the new attributes instead. For future reference you should avoid
  talking to Faraday directly.
  - `timeout` controls the general HTTP connection timeouts. It's set to
    1 minute by default which should be enough for most read operations.
  - `write_timeout` controls the HTTP connection timeout of writing timeouts.
    This applies in broad terms to all requests which we expect to require a
    server-side lock to run and thus have high potential for timing out.
    It defaults to 10 minutes which should allow most operations to finish.
    The attribute will have tighter functionality if or when
    https://github.com/smira/aptly/pull/459 gets merged and we can adopt a more
    async API.
- Connection.new now takes a new `config` parameter that is the Configuration
  instance to use for the Connection. This partially deprecates the `uri`
  parameter which you can set through the Configuration instance now.

  ```
  Aptly::Connection.new(uri: uri)
  # can become
  Aptly::Connection.new(Aptly::Configuration.new(uri: uri))
  ```

### Changed
- Connection.new no longer catches arbitrary options but instead specifies
  the accepted arguments in the method signature. It accepted two
  well-known options before anyway, this enforces them properly on a language
  level.

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
