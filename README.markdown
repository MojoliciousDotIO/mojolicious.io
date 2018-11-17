## mojolicious.io - A semi-official website dedicated to the Mojolicious web framework

This site is powered by [Statocles](http://preaction.me/statocles/).
To do anything fancy, please read more about it first.

To contribute to the site, clone the project and install the dependencies

```
$ git clone git@github.com:jberger/mojolicious.io.git
$ cd mojolicious.io
$ cpanm --installdeps .
```

Note that you might need to update your cpanm installation.
If the above fails, run `cpanm --self-upgrade` (or `perlbrew install-cpanm` depending on if you're using perlbrew, we do) and retry.

To serve the site locally, simply run `state daemon [--date YYYY-MM-DD]`.
To see it as of a different date, try the `--date` flag (useful if you want to postdate a blog post for example).
Note that it may take quite a while to startup, Statocles is powerful but it isn't very optimized yet.

To add a new post run `statocles blog post [--date YYYY-MM-DD] 'Title of your post'`, where again the optional date lets you create a post for a future date.

Then when you're done, run the server again to see how it looks.
Repeat until you're satisfied, when you are, open a PR.

## Tips

- Please keep all of your files in the post's directory (the one with index.html), this will help keep things orderly.
- Until we add some smarts to the calendar plugin, if you want to postdate a calendar entry, comment it out in the calendar page metadata, otherwise it will show up too early (or let us add it).
- Please don't commit the results of running the deploy command (in `live/` or worse in `.statocles/`), let us do that for you on the production server when its time.

## Acknowledgements and Legal

The style is Sparrow by [Styleshout](https://www.styleshout.com).

All content except where otherwise noted is copyright (c) 2017 Joel Berger.

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.
