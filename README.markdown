## mojolicious.io - A semi-official website dedicated to the Mojolicious web framework

This site is powered by [Statocles](http://preaction.me/statocles/).
To do anything fancy, please read more about it first.

To contribute to the site, clone the project and install the dependencies

```
$ git clone git@github.com:MojoliciousDotIO/mojolicious.io.git
$ cd mojolicious.io
$ cpanm --installdeps .
```

Note that you might need to update your cpanm installation.
If the above fails, run `cpanm --self-upgrade` (or `perlbrew install-cpanm` depending on if you're using perlbrew, we do) and retry.

To serve the site locally, simply run `statocles daemon [--date YYYY-MM-DD]`.
To see it as of a different date, try the `--date` flag (useful if you want to postdate a blog post for example).
Note that it may take quite a while to startup, Statocles is powerful but it isn't very optimized yet.

To add a new post run `statocles blog post [--date YYYY-MM-DD] 'Title of your post'`, where again the optional date lets you create a post for a future date.

Then when you're done, run the server again to see how it looks.
Repeat until you're satisfied, when you are, open a PR.

## Author Bios

If you are a new author, you should add biographical information into the the `site.yml` data under `site.args.data.bios.<<unique key>>`.
This unique key is then referenced in your article's `data.bio` topmatter yaml field.

Data in that object should contain at least `name` and `text` values containing your name (or pseudonym) and a blurb about you, respectively.
You are encouraged to also link an `image`.
If you have a publicly accessible image, like gravatar, you may use a full url to it.
Otherwise, add an image to this site's `static` directory and link to it.
Finally, if you have a twitter account, you may point to it with a `twitter` key.

```yaml
jberger:
    name: 'Joel Berger'
    twitter: '@joelaberger'
    image: 'https://secure.gravatar.com/avatar/cc767569f5863a7c261991ee5b23f147'
    text: |-
      Joel has Ph.D. in Physics from the University of Illinois at Chicago.
      He an avid Perl user and [author](https://metacpan.org/author/JBERGER) and is a member of the Mojolicious Core Team.
```

Other keys may be added but will need to be incorporated into the site renderer to take effect.
Please open an issue to discuss.

## Tips

- Please keep all of your files in the post's directory (the one with index.html), this will help keep things orderly.
- Until we add some smarts to the calendar plugin, if you want to postdate a calendar entry, comment it out in the calendar page metadata, otherwise it will show up too early (or let us add it).
- Please don't commit the results of running the deploy command (in `live/` or worse in `.statocles/`), let us do that for you on the production server when its time.

## Acknowledgements and Legal

The style is Sparrow by [Styleshout](https://www.styleshout.com).

All content except where otherwise noted is copyright (c) 2017 Joel Berger.

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.
