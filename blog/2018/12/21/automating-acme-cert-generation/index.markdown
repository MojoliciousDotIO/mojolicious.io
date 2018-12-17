---
status: published
title: Day 21: Automating ACME cert generation
author: Stefan Adams
images:
  banner:
    src: '/blog/2018/12/21/automating-acme-cert-generation/banner.jpg'
    alt: 'Factory Robot'
    data:
      attribution: |-
        Banner image: [Factory Robot](https://en.wikipedia.org/wiki/Automation#/media/File:KUKA_robot_for_flat_glas_handling.jpg) [Credits](https://commons.wikimedia.org/wiki/File:KUKA_robot_for_flat_glas_handling.jpg)
tags:
  - advent
  - acme
data:
  bio: s1037989
  description: Automating Mojo::ACME for continuous free SSL certs
---

Having encrypted websites is a very important thing to do; search engines are even giving higher SEO ranking for it.  With free certificates, there's really no excuse not to encrypt all web traffic any more!  I use Mojo::ACME to handle the (re-)generation of my ACME-signed SSL certificates and I use Mojolicious::Plugin::ACME::Command::acme::automate to automate the account registration and ACME-signed certificate generation for multiple domains, all in one go.

I like to centralize the responsibility of certificate (re-)generation to the gateway web server, and let the apps behind the protected gateway just be apps.  If I feel I need to also encrypt traffic from gateway to internal app, I can do that too, and I'll typically just use self-signed certs which Mojolicious specifically is already more than equipped to do.

The specific setup for which this article is intended is one in which there are one or more web servers (Mojolicious, Apache/PHP, etc) behind a reverse proxy such as [nginx](http://nginx.org) and each web server runs one or more apps with each app handling requests for one or more FQDN.  My typical setup is that I run a *production* Mojolicious [toadfarm](https://github.com/jhthorsen/toadfarm) on one LXC, a *staging* toadfarm on another LXC, and a *development* Mojolicious daemon or prefork on another LXC.  This will work just as well if the different web servers are on different VPS's or on the same VPS and not separated by containers.

<aside id="sidebar" mardown=1>
### My deployment process
*Each of these deployment stages are a different web server _process_ -- same box, different containers on the same box, different boxes across the galaxy...  doesn't matter.  What does matter to me is that each stage is a different _process_ to ensure isolation between the stages. We don't want buggy code testing to affect other stages' web server process(es).*
- Develop on the development web server, and daemon / prefork are best for that.  It provides the appropriate conveniences and ease of management, and should remain isolated from your users.  I like to even pass port 3000 straight through the firewall to my development instance just for quick proof-of-concept testing.  In general, I find that I still need to have a dedicated domain name and have it route through the standard port 80 (where the reverse proxy lives) because I do a lot of work with third-party APIs and many don't like to connect to a web server on a non-standard port.
- Deploy to staging.  When I want others to see my development work, I then "freeze" my work at a given moment and "publish" it to staging which is treated just like production in terms of uptime expectancy (probably fewer 9s) and so I use the same tools (e.g. toadfarm) and care as I would with production -- the exception is that, of course, it isn't *production* production.  My testing users expect to see a functional app and at their convenience -- it's a terrible practice to ever point users to your development box.  You'll want to keep working and changing things and you can't wait for your users to have tried out your changes before you continue work on development.
- Finally, when users are happy with what they see in staging, deploy to production!

*The techniques used for deploying are, for the purposes of this article, unimportant.*
</aside>

The intent of this article is to improve the convenience when it comes to managing one or more free ACME-based SSL certificates.  By then end, we'll have one or more simple `cron.monthly` scripts that register a new ACME account if necessary and then (re-)generate the ACME-signed certificates.  The gateway web server which already exists to reverse proxy to the web servers will intercept non-encrypted port 80 traffic destined for /.well-known (standard URL endpoint for ACME) and redirect these requests to the Mojo::ACME plugin.  The cron.monthly scripts will (re-)generate certificates and can create the reverse proxy configuration file based on a template.

## Now let's get to How

First install some basic packages.  This is on Ubuntu Bionic 18.04.

    $ sudo apt install \ 
        cpanminus \          # We'll use this to install the Perl modules
        build-essential \    # gcc and make and other essential build utilities necessary for building some Perl packages
        libssl-dev \         # For IO::Socket::SSL
        zlib1g-dev           # For Net::SSLeay which is needed for IO::Socket::SSL
    $ sudo cpanm \ 
        IO::Socket::SSL \    # Mojo::ACME and the SSL certificates that this article is about depends on this
        Mojolicious \        # No matter what you do in life, you need this
        Mojo::ACME \         # This is what is handling the certificate generation
        Mojolicious::Plugin::ACME::Command::acme::automate   # This is what is automating that certificate generation (`automate`, for short)

See [automate](https://github.com/s1037989/Mojolicious-Plugin-ACME-Command-acme-automate) for source.

We'll use nginx for the reverse proxy web server.

    $ sudo apt install nginx


## mojo-acme-server

mojo-acme-server is not a Perl module and it does not have an install script; therefore, it's currently advised to install to /opt.  It's not "released" anywhere like CPAN or packaged like a .deb, so we'll just clone from git.

    $ cd /opt && \ 
      sudo git clone git@github.com:s1037989/mojo-acme-server.git && \ 
      sudo chown -R ``whoami``.``whoami`` /opt/mojo-acme-server && \ 
      cd /opt/mojo-acme-server


Copy the sample config file and edit it.

    $ sudo cp mojo-acme-server.conf.sample mojo-acme-server.conf && \ 
      sudo $EDITOR mojo-acme-server.conf

Set the logfile, ssldir, and webdir locations as you see fit.  `ssldir` is where the generated SSL certificate and private key files go.  `webdir` is where the template-based reverse proxy config file goes if you wish to generate one.

Copy the sample cron.monthly script to /etc/cron.monthly and edit it.

    $ sudo cp example/cron.monthly /etc/cron.monthly/acme && \ 
      sudo $EDITOR /etc/cron.monthly/acme

You could put all your automate commands into the single acme script, or you could organize it into multiple scripts -- it makes no difference.  Each run of the acme automate command is a single certificate for all the specified domains.  No need to configure it to run more than once per month as ACME-signed certificates are good for 90 days.  The most important options to set are -l (listen), -o (option), and the host(s).  Set -l to listen the same as what nginx intends to proxy_pass to and (perhaps among other things) set the proxy_pass URL that the reverse proxy should proxy pass encrypted connections to for the domains on that certificate.  Among other parameters, optionally set the template to use (-T).

    /opt/mojo-acme-server/mojo-acme-server acme automate \    # this is the `automate` Perl module we installed earlier
      -T nginx_default \    # You can have any number of templates, `automate` comes with a sample nginx config
      -l http://*:8928 \    # Set mojo-acme-server to listen on whatever random port (and make sure the nginx configuration directive (from `extra/acme`) points to a URL that this listen configuration will pick up)
      -o proxy_pass=http://127.0.0.1:3000 \    # This is the URL to pass the encrypted traffic to, in this case it's my development Mojolicious daemon
      example.com www.example.com    # These are the FQDN that this app will handle requests for

Templates are stored in templates/.  Copy the sample and modify to your liking.

    $ sudo cp templates/nginx_default.ep.sample templates/nginx_default.ep && \ 
      sudo $EDITOR templates/nginx_default.ep

Once a config file has been written, it won't be rewritten -- there's typically no reason to.  Therefore, feel free to modify your individual generated config files to continue to optimize for that app's purposes.

## Nginx

It would be super nice to have a single, simple nginx config file with variables instead of a new configuration directive for every certificate needed; but it's understandable why there's not: [It is too expensive to use variables in some nginx configuration directives](http://nginx.org/en/docs/faq/variables_in_config.html).  Therefore, one of the main steps in automate is to generate a new template-based config file for each generated certificate -- it helps to keep the generated certificates and the corresponding reverse proxy configurations in sync.

<aside id="sidebar" mardown=1>
Real quick, modify the log format of nginx so you can quickly see which host is being requested.  *(Why isn't this the default??)*  In /etc/nginx/nginx.conf, define a log_format and then set the access log to use it.

    log_format main '$remote_addr - $remote_user [$time_local] "$host" "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" $request_time';
    access_log /var/log/nginx/access.log main;    # Notice: it's calling the log format named `main` that was defined just above
</aside>

Moving on, copy the sample `acme` nginx config file for handling the ACME protocol HTTP requests and edit it.

    $ cd /opt/mojo-acme-server && \ 
      sudo cp example/nginx /etc/nginx/sites-available/acme && \ 
      sudo ln -s /etc/nginx/sites-available/acme /etc/nginx/sites-enabled && \ 
      sudo $EDITOR /etc/nginx/sites-available/acme

Most importantly, set the proxy_pass URL for where you configured mojo-acme-server to listen.  In this article, mojo-acme-server is running on the same server instance as nginx, on random port 8928.  We're telling nginx to proxy_pass data to the specified URL, where we earlier configured mojo-acme-server to listen on port 8928.  nginx is listening on port 80/443 as it is *the* gateway for all of our web apps (Mojolicious, Apache/PHP, node.js, etc).

    proxy_pass http://127.0.0.1:8928


## Test it

First, register your new ACME account and generate a new certificate.  On success, the reverse proxy will be restarted.

    $ sudo /etc/cron.monthly/acme

That's it!  The cron.monthly script runs the automate command that does all the automation!

Test that your new certs have been generated well.

    $ openssl x509 -in /etc/ssl/mojo-acme-server-cert-example.com.crt -noout -text || echo Fail

If that fails, I got nothin' for ya, sorry.  :(  I built automate for the purpose of this article, so it's not exactly well tested or stressed -- PRs welcome!!
If it succeeds, proceed to access your newly encrypted website through a browser.  Fire up a web server on the port that automate was configured to proxy_pass HTTP requests to.

    $ perl -Mojo -E \ 
      'a("/"=>sub{shift->render(text=>scalar localtime)})->start' \  # Simple app that just responds with the current time
      daemon \            # This is a complete Mojolicious web server,
      -l http://*:3000    # listening on port 3000


Then load it up in your web browser.  Do this on your personal workstation as opposed to the VPS instance running your nginx gateway.

    $ curl https://example.com
