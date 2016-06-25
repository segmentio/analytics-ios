Contributing
============

If you would like to contribute code to `analytics-ios` you can do so through
GitHub by forking the repository and sending a pull request.

Development occurs on the `dev` branch, and pull requests must be opened against
the `dev` branch. Every second Wednesday, `master` is taggged and released, and
`dev` is merged into `master`. In general, code will be available on `master`
for two weeks before being tagged as a stable release.

Critical bug fixes will be cherry picked into `master` after being merged into
`dev` and released immediately.

When submitting code, please make every effort to follow existing conventions
and style in order to keep the code as readable as possible. Please also make
sure your code compiles by running `make build test`.
