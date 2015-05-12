### License Checker

Use the [GitHub API](https://developer.github.com/v3/) to find all private
repositories owned by an organization which have license files (and hence may
be granting an open source license to people who have access to the code).

### Usage

 - [Create a GitHub personal access token.](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) This should be made by a member of the organization who can see private repositories (e.g., a member of the `Owners` team).
 - Place the access token in the file `~/.github.yml`:

``` yaml
token: 1234567890feedfacedeadbeefcafe0987654321
```

 - Bundle, and run the script, providing the github account name for your org:

```
$ bundle install --path vendor
$ bundle exec script/find-licensed-private-repos.rb your-org-name-here
```

You can also set the environment variable `$DEBUG` if you want more verbose output during the fetch process.
