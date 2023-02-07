#!/usr/bin/env bash
REPO=chanzuckerberg/happy
MIRROR=chanzuckerberg/terraform-provider-happy
# don't paginate since we already did a bulk mirror before
# only need to grab the latest stuff
RELEASES=$(gh api -H "Accept: application/vnd.github.v3+json" /repos/chanzuckerberg/happy/releases -q "[.[] | select(.tag_name | startswith(\"v\")) | .tag_name]" | jq -s "flatten(1)")

for i in $(echo $RELEASES | sed -e 's/\[ //g' -e 's/\ ]//g' -e 's/\,//g'); do
  RELEASE=$(echo $i | tr -d '"')
  gh release view $RELEASE -R $MIRROR > /dev/null 2>&1
  status=$?
  # we already have the release
  if [ $status -eq 0 ]
  then
    echo "$RELEASE> Already have this release, skipping."
    continue
  fi

  echo "$RELEASE> Creating tags"
  git tag "$RELEASE" > /dev/null 2>&1

  echo "$RELEASE> Pushing tags"
  git push origin --tags > /dev/null 2>&1

  echo "$RELEASE> Downloading release to /tmp/$RELEASE"
  gh release download $RELEASE --pattern "happy_provider*" -D "/tmp/$RELEASE" -R $REPO > /dev/null 2>&1
  status=$?
  # we already have the release
  if [ $status -eq 1 ]
  then
    echo "$RELEASE> No provider assests, skipping."
    continue
  fi

  echo "$RELEASE> Creating release"
  gh release create --generate-notes $RELEASE /tmp/$RELEASE/* -R $MIRROR > /dev/null 2>&1

  echo "$RELEASE> Cleaning up"
  rm -rf "/tmp/$RELEASE"
done