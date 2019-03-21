---
status: published
title: Testing Environment With Tmux
disable_content_template: 1
tags:
    - development
    - testing
    - yancy
author: Doug Bell
images:
  banner:
    src: '/blog/2019/04/15/testing-environment-with-tmux/banner.png'
    alt: 'Text saying "Tmux" in the middle of white, red, yellow, and blue boxes containing shell output separated by thick black lines. Original artwork by Doug Bell'
    data:
      attribution: |-
        Original artwork by Doug Bell (licensed CC-BY-SA 4.0).
data:
  bio: preaction
  description: 'Use Tmux to build development environments for your projects'
---

The [Yancy CMS](http://preaction.me/yancy) for the [Mojolicious web
framework](http://mojolicious.org) currently supports three different
database systems directly (and even more through [the DBIx::Class
ORM](http://dbix-class.org)). As a result, when doing development,
I need to have two database daemons running locally, a bunch of
different environment variables to tell the tests where those databases
are, and a web daemon to test the front-end.

Setting up these daemons is a pain, but I also do not want to run them
all the time (to save on my laptop's battery). To me, it's easier to run
a database daemon for a specific project than to try to manage all the
databases I might need. But that means that every time I want to do some
work on Yancy, I need to start up a bunch of things.

Since I do all my development in a terminal window, [the Tmux terminal
multiplexer](http://tmux.github.io) has become an extremely useful tool.
Using a shell script and Tmux, I can run a single command to set up all
the databases, environment variables, and all the tabs I need to get to
work quickly.

---

[Tmux](http://tmux.github.io) allows me to set up multiple "windows" in
a single terminal, kind of like tabs in a browser. Each window can then
be split into panes horizontally and vertically. Each pane has a program
running inside, usually a shell (like bash) that I can run commands in
(like vim, my editor). I can do all this by typing commands in the tmux
session: <kbd>Ctrl+B C</kbd> to create a new window, <kbd>Ctrl+B %</kbd>
to split the current pane vertically, <kbd>Ctrl+B "</kbd> to split the
current pane horizontally, etc...

![A Tmux window showing three panes with Vim and other commands running](tmux-example.png)

But, I can also interact with Tmux via the `tmux` command. Everything
I can do by typing in the Tmux session I can do with the `tmux` command:
`tmux new-window` creates a new window, `tmux split-pane -v` splits
a pane vertically, `tmux split-pane -h` splits a pane horizontally. By
using these commands, I can set up a complex set of windows and panes in
Tmux inside a shell script:

    tmux new-session -s yancy -d
    tmux new-window -t yancy:2
    tmux send-keys -t yancy:1 vim Enter
    tmux send-keys -t yancy:2.0 "export TEST_YANCY_EXAMPLES=1" Enter

![A Tmux window showing the Vim editor](window-1.png)

![A Tmux window showing a shell with TEST_YANCY_EXAMPLES environment
variable set](window-2.png)

First, I create a new Tmux session named "yancy" and create a new
window. Then I run `vim`, my editor, in the first window, and set up an
environment variable in the second window. Next I need to run my
databases. I create a new window to run
[Postgres](https://www.postgresql.org) in one pane, and then split that
pane to run [MySQL](https://www.mysql.com) in the other pane.

    tmux new-window -t yancy:3 postgres -D ~/perl/Yancy/db/pg
    tmux split-window -t yancy:3 mysqld --skip-grant-tables --datadir ~/perl/Yancy/db/mysql

![A Tmux window with two panes showing Postgres and MySQL running](window-3.png)

Finally, I need to attach to my session. But also, if my session is
already running, I don't want to initialize it again. So, I wrap the
entire thing in a shell conditional.

    if ! tmux has-session -t yancy; then
        tmux new-session -s yancy -d
        # ... Initialize the session
    fi
    tmux attach -t yancy

Now with one command I'm ready to develop! This script is available [in
the Yancy repository for anyone to
use](https://github.com/preaction/Yancy/blob/master/xt/tmux-layout.sh).
Tmux makes working on Yancy easy!
