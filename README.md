Reveal.js with Podman
=====================

Adjust `vars` to your liking. Based on
[cloudogu/reveal.js-docker](https://github.com/cloudogu/reveal.js-docker).

Then run `./startPresentation.sh`.

UIDs
====

I had to modify the following files:

```
$ cat /etc/subgid
avollmer:10000:2119470585
$ cat /etc/subuid
avollmer:10000:2119470585
```

Then run `podman system migrate` once.
