---
title: 'Day 16: The Secret Life of Sessions'
tags:
    - advent
    - session
author: Joel Berger
images:
  banner:
    src: '/static/scrabble.jpg'
    alt: 'Pile of Scrabble tiles'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=54930070">Image</a> by <a rel="nofollow" class="external text" href="https://www.flickr.com/people/30478819@N08">Marco Verch</a> - <a rel="nofollow" class="external text" href="https://www.flickr.com/photos/30478819@N08/31421007673/">Scrabble</a>, <a href="http://creativecommons.org/licenses/by/2.0" title="Creative Commons Attribution 2.0">CC BY 2.0</a>.
data:
  bio: jberger
  description: Use the session secret effectively to protect users without inconveniencing them.
---

As you all know, HTTP is a stateless protocol.
In Mojolicious applications the session is used to maintain state between requests.
These sessions are managed by the application's [session manager](http://mojolicious.org/perldoc/Mojolicious/#sessions).

During each request, the [session](http://mojolicious.org/perldoc/Mojolicious/Controller#session) is just another hash reference attached to the controller, in some ways like the [stash](/blog/2017/12/02/day-2-the-stash), except this one persists between requests.
Mojolicious does this by encoding the structure, first as JSON then Base64.
It then signs the resulting string using HMAC-SHA1 and the application's [secret](http://mojolicious.org/perldoc/Mojolicious#secrets) to prevent tampering and stores it as a cookie on the response to the client.

On subsequent requests, the client sends the cookie along with the request (as cookies do).
Mojolicious then checks if the document and signature validate against the secret, if so the cookie is decoded and made available again via the session method.

Two important things to note.
First, though the data is safe from tampering, it isn't encrypted; a savvy user can decode the cookie and see the stored data, so don't put anything in it that shouldn't be seen.
Second, this is only useful if the secret is strong and safe.
If not, the client could forge a cookie that appeared to come from your application, possibly with catastrophic results!
So while Mojolicious makes it easy, a little care can go a long way toward keeping your session data safe and trusted.
---

## A Simple Session Example

A very simple application that could use the session would be to store a counter of the user's visits to the site.

%= highlight 'Perl' => include -raw => 'app1.pl'

When you run this application

    $ perl myapp.pl daemon

and visit `localhost:3000` you should see a counter that increments on each request.
That data is stored on the client (e.g. in the browser) between each request and is incremented on the server before sending it back to the client.
Each response is a new cookie with the new session data and a new cookie expiration time, [defaulting to one hour](http://mojolicious.org/perldoc/Mojolicious/Sessions#default_expiration) from issue.
This also therefore implies that as long as you visit often enough (before any one cookie expires) and your data continues to validate against the secret, your session can last forever.

## Secret Security

Now, one other thing you should see is that in your application's log output, you should have a message like

    Your secret passphrase needs to be changed

This happens because you are using the default secret for the application.
This default is just the name of the script, as you can see via the [eval command](/blog/2017/12/05/day-5-your-apps-built-in-commands)

    $ perl myapp.pl eval -V 'app->secrets'
    [
      "myapp"
    ]

This secret is not secure both because it is short and because it is easy to guess.
With a trivial application like this you might not need to worry about forgery, as you would with say a session that tracks user logins.
But who knows, perhaps you are going to award a prize to the user for the most requests made!
Let's play it safe.

The secret isn't something you need to remember, it just has to be hard to guess.
So I suggest you pick a random one.
You could generate 12 characters of random text using

    $ </dev/urandom base64 | head -c 12
    yuIB7m88wS07

Once you have that you have to tell the app to use it.
Create a file called `myapp.conf` and set it up like so

%= highlight 'Perl' => include -raw => 'app2.conf'

Where the value is whatever secret you generated.
Notice that it is in an array reference, we'll talk about why soon.
Before that, let's tweak the application so that it uses that configuration

%= highlight 'Perl' => include -raw => 'app2.pl'

If it finds a `secrets` parameter in your configuration, it will set it as the `secrets` on your application.
Since you have one in your new configuration file, it should set that property and the warning should go away.
Congratulations, you have a safer application already!

If sometime later, you suspect that someone has guessed your secret, or if your secret leaks out, you can change that secret and restart your application.
This will protect your application from malicious users.

For your clients, this will have the jarring effect that all existing sessions will be invalidated.
In the example application the counter would be reset.
If instead the session were being used to keep users logged in, they would suddenly be logged out.
If it was for tracking a shopping cart ... no more shopping cart.

This can actually be useful even if your secret is safe but you want to force-invalidate sessions for some other reason, like say your application was generating corrupt data or worse.
Generally, however, this is something you'd like to avoid.

## A Random Secret?

Now perhaps you are asking yourself, if Mojolicious knows I'm using the insecure default couldn't it just set a random secret?
Sure, and you could do so yourself too if you wanted.
Something as easy as this would set a random secret.

%= highlight 'Perl' => include -raw => 'app3.pl'

So why isn't this recommended?
Because it would mean that each time you started the server you would get a new secret.
As with the case of changing your secret intentionally above, all existing sessions would be invalidated any time you wanted to reboot a server or restart the server process.
Additionally you could only use one server, any load balancing scenario would result in different secrets on different hosts, your users would randomly invalidate their sessions depending on which server they hit!

## Forward Secrecy

Just as you have to change application passwords from time to time, so too you need to change your secret.
In a brute force scenario, a nefarious user could take one of their cookies and try to reverse engineer the secret that was used to generate it.

But wait!
You just said that changing the secret to prevent brute forcing will invalidate all of our sessions!

Remember when I pointed out that rather than being a single value, `secrets` was an array reference?
Well when Mojolicious generates a session cookie, it does so using the first value in the array reference.
However, when it validates session signatures, it will check them against each secret in the array.

So, say the time has come to rotate our secrets so we generate another

    $ </dev/urandom base64 | head -c 12
    w8S4b+90CWwf

add that value to the configuration file

%= highlight 'Perl' => include -raw => 'app2.conf2'

and restart the application.
Any requests with valid sessions will still work.
The reply they receive will contain a new session cookie, as always, but this time it will be issued using the new secret!

Requests issued by the old credentials will slowly be replaced by new ones as clients each make their first requests following the change.
Once you wait long enough that any valid session cookie would have expired, you can remove the old secret from the configuration and restart again.

## Restarting

This is a good time to mention [`hypnotoad`](http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Hypnotoad).
It is Mojolicious' recommended production application server.
It has many of the same characteristics as the [`prefork`](http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Pre-forking) server but with some tuned settings and one killer feature, [zero downtime restarts](http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Zero-downtime-software-upgrades).

Note that on native Windows, `hypnotoad` will not work.
That said, it works great on the new [Windows Subsystem for Linux](https://blogs.msdn.microsoft.com/wsl/)!

A major usage difference is that hypnotoad (for technical reasons) can't use command line parameters.
Instead it takes its parameters via configuration.
It also starts on port `8080` rather than `3000` to prevent accidentally exposing your development servers unexpectedly.
For now however, let's set it back, more for an example than any particular reason.

%= highlight 'Perl' => include -raw => 'app2.conf3'

Rather than starting you application like

    $ perl myapp.pl daemon

use the `hypnotoad` script

    $ hypnotoad myapp.pl

The application should again be available on port `3000`.

You'll see that rather than staying in the foreground like with `daemon` the command returns and you get your prompt back.
Don't worry, as long as it said that it started it should stay running.
To stop the application, run the same commmand but also pass a `-s` switch

    $ hypnotoad -s myapp.pl

The really interesting thing happens when restarting a running application.
Say you've rolled your secrets and want to restart the application to use it.
Simply run the command as before, just like when you started it up.

Any requests currently being served by the old server processes will continue to be served by them (up to some timeout).
Any new requests will be served by new processes using the new configuration.
You don't cut off any users in the process.

Actually `hypnotoad` can be used to zero downtime restart for more reasons than just configuration changes.
It can handle changes to your application, updating dependencies, or even upgrading your version of Perl itself!

For now though, we're just satisfied that clients are none the wiser that you rolled the application secret out from under them without losing any connections nor invalidating any sessions.

