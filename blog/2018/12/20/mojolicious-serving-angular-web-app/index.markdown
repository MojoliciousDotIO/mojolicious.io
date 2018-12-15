---
title: Day 20: Mojolicious serving Angular Web App
disable_content_template: 1
tags:
  - advent
  - Mojolicious
  - Angular
author: Sachin Dangol
images:
  banner:
    src: '/blog/2018/12/20/mojolicious-serving-angular-web-app/banner.jpg'
    alt: 'backend and frontend'
    data:
      attribution: |-
        photo by [http://josephmedia.com/product/web-development/](http://josephmedia.com/product/web-development/)
        
data:
  bio: sachindangol
  description: 'Learn how to marry Mojolicious and Angular for building awesome web application'
---

### Mojolicious and Angular
[Angular](https://angular.io/) is arguably the best front-end web application framework which helps you build modern applications for the web, mobile, or desktop
[Mojolicious](https://mojolicious.org/), a next generation web framework for the Perl programming language.
Mojolicious and Angular together can certainly build a next gneration web framework.

At work, we have been using these two to build a very responsive, scalable and fantastic web apps. 
Mojolicious as a backend gives a lot of fun to work stuffs like Minion, Mojo::Dom, testing modules, easy implementaion of OpenAPI, OAuth, utility modules and many more.

We will see how these two can be married to make a web application today.

### Generate Mojolicious Full App

    Sachin@01:07 PM[~/workspace/project/mojo_angular]$ mojo generate app MojoAngularApp
      [mkdir] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/script
      [write] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/script/mojo_angular_app
      [chmod] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/script/mojo_angular_app 744
      [mkdir] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/lib
      [write] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/lib/MojoAngularApp.pm
      [exist] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app
      [write] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/mojo_angular_app.conf
      [mkdir] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/lib/MojoAngularApp/Controller
      [write] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/lib/MojoAngularApp/Controller/Example.pm
      [mkdir] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/t
      [write] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/t/basic.t
      [mkdir] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/public
      [write] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/public/index.html
      [mkdir] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/templates/layouts
      [write] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/templates/layouts/default.html.ep
      [mkdir] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/templates/example
      [write] /Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/templates/example/welcome.html.ep
    Sachin@01:07 PM[~/workspace/project/mojo_angular]$ cd mojo_angular_app/
    Sachin@01:08 PM[~/workspace/project/mojo_angular/mojo_angular_app]$ hypnotoad -f script/mojo_angular_app 
    [Sat Dec 15 13:08:52 2018] [info] Listening at "http://*:8080"
    Server available at http://127.0.0.1:8080
    [Sat Dec 15 13:08:52 2018] [info] Manager 38209 started
    [Sat Dec 15 13:08:52 2018] [info] Creating process id file "/Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/script/hypnotoad.pid"
    [Sat Dec 15 13:08:52 2018] [info] Worker 38210 started
    [Sat Dec 15 13:08:52 2018] [info] Worker 38211 started
    [Sat Dec 15 13:08:52 2018] [info] Worker 38213 started
    [Sat Dec 15 13:08:52 2018] [info] Worker 38212 started

<img class="align-center" src="mojo_app.png" title="basic mojolicous full app">

### Generate Angular App

    Sachin@01:18 PM[~/workspace/project/mojo_angular]$ ng new NgDemo
    ? Would you like to add Angular routing? Yes
    ? Which stylesheet format would you like to use? CSS
    CREATE NgDemo/README.md (1023 bytes)
    CREATE NgDemo/angular.json (3768 bytes)
    CREATE NgDemo/package.json (1306 bytes)
    ...

    Sachin@01:20 PM[~/workspace/project/mojo_angular]$ cd NgDemo/
    Sachin@01:20 PM[~/workspace/project/mojo_angular/NgDemo]$ ls
    README.md         angular.json      e2e               node_modules      package-lock.json package.json      src               tsconfig.json     tslint.json
    Sachin@01:20 PM[~/workspace/project/mojo_angular/NgDemo]$ ng serve
    ** Angular Live Development Server is listening on localhost:4200, open your browser on http://localhost:4200/ **
                                                                                          
    Date: 2018-12-15T05:22:00.337Z
    Hash: c05a16d8553980a82a62
    Time: 36103ms
    chunk {main} main.js, main.js.map (main) 11.5 kB [initial] [rendered]
    chunk {polyfills} polyfills.js, polyfills.js.map (polyfills) 223 kB [initial] [rendered]
    chunk {runtime} runtime.js, runtime.js.map (runtime) 6.08 kB [entry] [rendered]
    chunk {styles} styles.js, styles.js.map (styles) 16.3 kB [initial] [rendered]
    chunk {vendor} vendor.js, vendor.js.map (vendor) 3.67 MB [initial] [rendered]
    ｢wdm｣: Compiled successfully.

<img class="align-center" src="angular_app.png" title="basic angular app">    

### How to make Mojolicious app serve angular single page app(SPA)?
##### Prepare angular app to be deployed in mojolicious:

    Sachin@02:06 PM[~/workspace/project/mojo_angular/NgDemo]$ ng build 
                                                                                          
    Date: 2018-12-15T06:06:48.550Z
    Hash: f3749aba56348b1e51e3
    Time: 27091ms
    chunk {main} main.js, main.js.map (main) 10.3 kB [initial] [rendered]
    chunk {polyfills} polyfills.js, polyfills.js.map (polyfills) 223 kB [initial] [rendered]
    chunk {runtime} runtime.js, runtime.js.map (runtime) 6.08 kB [entry] [rendered]
    chunk {styles} styles.js, styles.js.map (styles) 16.3 kB [initial] [rendered]
    chunk {vendor} vendor.js, vendor.js.map (vendor) 3.35 MB [initial] [rendered]
    Sachin@02:06 PM[~/workspace/project/mojo_angular/NgDemo]$

###### Above command creates a **dist** directory:

    Sachin@02:10 PM[~/workspace/project/mojo_angular/NgDemo]$ ls
    README.md         angular.json      dist              e2e               node_modules      package-lock.json package.json      src               tsconfig.json     tslint.json
    Sachin@02:10 PM[~/workspace/project/mojo_angular/NgDemo]$   

###### Copy everything within the folder dist/ to a folder on the public directory in Mojolicious app

    Sachin@02:12 PM[~/workspace/project/mojo_angular/NgDemo]$ cd dist
    Sachin@02:13 PM[~/workspace/project/mojo_angular/NgDemo/dist]$ ls NgDemo
    Sachin@02:13 PM[~/workspace/project/mojo_angular/NgDemo/dist]$cp -R NgDemo ~/workspace/project/mojo_angular/mojo_angular_app/public/
    Sachin@02:13 PM[~/workspace/project/mojo_angular/NgDemo/dist]

##### Modify ~/workspace/project/mojo_angular/mojo_angular_app/lib/MojoAngularApps.pm (full app module) to serve the angular app:

    package MojoAngularApp;

    use Mojo::Base 'Mojolicious';

    # This method will run once at server start       
    sub startup {
        my $self = shift;

        # Load configuration from hash returned by "my_app.conf"                                                                         
        my $config = $self->plugin('Config');
        # Documentation browser under "/perldoc"                                       
        $self->plugin('PODRenderer') if $config->{perldoc};

        # Router                                          
        my $r = $self->routes;
    
        # serve angular SPA located at static page location                                                                              
        push @{$self->static->paths} => '/home/sachin/workspace/project/mojo_angular/mojo_angular_app/public/NgDemo';

        # Normal route to controller                      
        $r->get('/')->to('example#welcome');
    }

    1;

Magic line above is:

    push @{$self->static->paths} => '/home/sachin/workspace/project/mojo_angular/mojo_angular_app/public/NgDemo';

##### Run hypnotoad to see if angular page is served

    Sachin@02:48 PM[~/workspace/project/mojo_angular/mojo_angular_app]$ hypnotoad -f script/mojo_angular_app 
    [Sat Dec 15 14:49:03 2018] [info] Listening at "http://*:8080"
    Server available at http://127.0.0.1:8080
    [Sat Dec 15 14:49:03 2018] [info] Manager 40633 started
    [Sat Dec 15 14:49:03 2018] [info] Creating process id file "/Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/script/hypnotoad.pid"
    [Sat Dec 15 14:49:03 2018] [info] Worker 40634 started
    [Sat Dec 15 14:49:03 2018] [info] Worker 40635 started
    [Sat Dec 15 14:49:03 2018] [info] Worker 40637 started
    [Sat Dec 15 14:49:03 2018] [info] Worker 40636 started

<img class="align-center" src="mojo_serving_angular.png" title="mojolicious serving angular SPA">    

###### Obviously the page is blank as we din't write any code in our angular app. However, we are sure that mojolicious is serving the page as it din't throw 404 error and also we see the title of the page is 'NgDemo' which is coming from the index.html:

    Sachin@02:55 PM[~/workspace/project/mojo_angular/mojo_angular_app/public/NgDemo]$ cat index.html 
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>NgDemo</title>
      <base href="/">

      <meta name="viewport" content="width=device-width, initial-scale=1">
      <link rel="icon" type="image/x-icon" href="favicon.ico">
    </head>
    <body>
      <app-root></app-root>
    <script type="text/javascript" src="runtime.js"></script><script type="text/javascript" src="polyfills.js"></script><script type="text/javascript" src="styles.js"></script><script type="text/javascript" src="vendor.js"></script><script type="text/javascript" src="main.js"></script></body>
    </html>
    Sachin@02:55 PM[~/workspace/project/mojo_angular/mojo_angular_app/public/NgDemo]$

##### For more example code to see more Angular and Mojolicious in action, please have a look at my git repo:
[https://github.com/tryorfry/mojolicious-ng4](https://github.com/tryorfry/mojolicious-ng4)



