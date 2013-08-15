Cutting a New Release
=====================

## Follow [Semver](http://semver.org)

Not optional; do it.

## Commit Structure

When you are ready to cut a new release, do it all in a single commit
on master.  Don't worry about being fancy and folding it into a merge
commit.

This commit should contain the `metadata.rb` change, as well as the
updated `CHANGELOG.md`.  Set the commit message to something like
`"Bump version to X.X.X"`.

## Bump the version in [metadata.rb](metadata.rb)

Otherwise what's the point?

## Add Entry to [CHANGELOG.md](changelog.md)

Follow the established format, adding a note for each significant
change that was introduced since the previous release.  Make sure to
add any pertinent information relevant for deploying using this new
version.

The point is to make it easy for anybody to figure out what changes
they would get by updating to this new version, and what additional
actions (if any) they would need to make.

## Add new tag

All releases should be tagged for easy retrieval later.

``` sh
    git tag --annotate 'X.X.X' --message='Cut new release'
```

The message for the annotated tag doesn't so much matter, given that
we're using a change log.  You can just use the literal message `Cut
new release` if you like.

## Push It All Out

``` sh
    git push --tags opscode-cookbooks master
```

Don't forget the `--tags` bit, or you won't push out the new tag you
just made.

## Upload and Deploy to Preprod

We don't (yet) lock cookbook versions in preprod; once you upload a
new cookbook, that's what'll get used on the next `chef-client` run.

``` sh
    cd $PREPROD
    knife cookbook upload opscode-bifrost --freeze

    knife ssh role:opscode-bifrost 'sudo chef-client' # or whatever you need to do
```

## Upload and Deploy to Prod

In prod, however, we _do_ use environment-locking of cookbooks.

``` sh
    cd $PROD
    git checkout rs-prod # NOT master! :'(
    git fetch origin
    git pull origin rs-prod
    $EDITOR environments/rs-prod.json # update the opscode-bifrost cookbook version
```

As a safety check, make sure to do a diff of the environment file
against the Chef server to ensure that you won't inadvertently clobber
any other in-flight changes.

``` sh
    knife diff environments/rs-prod.json
```

When all is good, upload to the Chef server:

``` sh
    knife environment from file environments/rs-prod.json
```

Then, go do what you gotta do:

``` sh
    knife ssh role:opscode-bifrost 'sudo chef-client'
```

Alternatively, do it manually / interactively:

``` sh
    knife ssh role:opscode-bifrost csshx # you don't use CSSHX?  Why do you hate yourself?
```

Dont' forget to commit your changes to the
`opscode-platform-cookbooks` repo!

## Consider Applicability to Enterprise Chef

[Enterprise Chef][] does not currently use this cookbook for its
bifrost deployment.  When you make a change here, consider whether or
not Enterprise Chef needs an equivalent update.  It is legitimate to
_not_ require changes to Enterprise Chef; for instance, if your
changes pertain solely to Hosted Enterprise Chef.

[Enterprise Chef]:https://github.com/opscode/opscode-omnibus/tree/master/files/private-chef-cookbooks/private-chef
