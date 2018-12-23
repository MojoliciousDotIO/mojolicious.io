---
title: Day 23: Mojolicious and Angular
disable_content_template: 1
tags:
  - advent
  - Angular
  - JavaScript
author: Sachin Dangol
images:
  banner:
    src: '/blog/2018/12/23/mojolicious-and-angular/banner.jpg'
    alt: 'Spider in web'
    data:
      attribution: |-
        Banner [photo](https://commons.wikimedia.org/w/index.php?curid=646036) by [Vincent de Groot](http://www.videgro.net/), licensed [CC BY SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)

data:
  bio: sachindangol
  description: 'Learn how to marry Mojolicious and Angular for building awesome web application'
---

[Angular](https://angular.io/) is one of the most popular front-end web application frameworks, helping you build modern applications for the web, mobile, or desktop.
[Mojolicious](https://mojolicious.org/) is a next generation web framework for the Perl programming language.
Mojolicious and Angular together can certainly build a next generation web application.

At work, we have been using these two to build a very responsive, scalable and fantastic web apps.
Mojolicious as a backend gives a lot of fun to work stuffs like [Minion](https://mojolicious.org/perldoc/Minion), [Mojo::DOM](https://mojolicious.org/perldoc/Mojo/DOM), [Test::Mojo](https://mojolicious.org/perldoc/Test/Mojo).
It has many plugins, including easy implementation of [OpenAPI](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI), [OAuth](https://metacpan.org/pod/Mojolicious::Plugin::OAuth2), utility modules and of many others on CPAN.

One of the reasons you want to have this kind of web development set up is that front-end Angular developers and backend Mojolicious developers can work independently.

Angular is backend agnostic. Node.js Express is often used as backend for Angular, but we love Perl and Mojolicious.

We will see how these two can be married to make a web application today.

---

I will be using the default auto-generated apps from both Mojolicious using [mojo](https://mojolicious.org/perldoc/Mojolicious/Commands) and Angular using [Angular CLI](https://angular.io/cli).

## Generate Mojolicious Full App

First I generate mojo full app using `mojo` CLI's [generate app](https://mojolicious.org/perldoc/Mojolicious/Command/generate/app) command.

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
    Sachin@01:07 PM[~/workspace/project/mojo_angular]$

Now that the Mojolicious full-app is created, start [hypnotoad](https://mojolicious.org/perldoc/Mojo/Server/Hypnotoad), a production web server.

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

Let's open browser and have a look at our mojo app.

![basic Mojolicious full app](mojo_app.png)


## Generate Angular App

Angular Version 7 is used for this demo, but should work for versions back to 4+. Demos on how to install Angular and CLI will be way too boring for this blog and there are plenty of resources for this in internet.

Angular CLI is a command-line interface tool that you use to initialize, develop, scaffold, and maintain Angular applications.
Let's use the Angular CLI to generate a new app, `ng new app-name`.

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

Now for the moment, let's start the built-in angular server with `ng serve` command.

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

Open the browser to check Angular app:

![basic angular app](angular_app.png)

Note that this page's content is coming from `NgDemo/src/index.html` where `app-root` selector html is content coming from `NgDemo/src/app/app.component.html`. Later we will be modifying `app.component.html` file to show our own content instead of default angular logo and some links.

## Make Mojolicious app serve an Angular app?

First we'll compile the Angular app from [TypeScript](https://www.typescriptlang.org/docs/home.html) to standard JavaScript.
`ng build` compiles an Angular app into an output directory named `dist` at the given output path.
Run `ng build` with `--base-href=./` so that base url inside the Angular app is set to the current directory for the application being built. This is very important so that later you do not waste time figuring out why Angular routes are broken when served by Mojolicious. This option makes sure that Anguar app's routing mechanism is set up referencing `./`(present directory of app) directory.

    Sachin@02:06 PM[~/workspace/project/mojo_angular/NgDemo]$ ng build --base-href=./

    Date: 2018-12-15T06:06:48.550Z
    Hash: f3749aba56348b1e51e3
    Time: 27091ms
    chunk {main} main.js, main.js.map (main) 10.3 kB [initial] [rendered]
    chunk {polyfills} polyfills.js, polyfills.js.map (polyfills) 223 kB [initial] [rendered]
    chunk {runtime} runtime.js, runtime.js.map (runtime) 6.08 kB [entry] [rendered]
    chunk {styles} styles.js, styles.js.map (styles) 16.3 kB [initial] [rendered]
    chunk {vendor} vendor.js, vendor.js.map (vendor) 3.35 MB [initial] [rendered]
    Sachin@02:06 PM[~/workspace/project/mojo_angular/NgDemo]$

Note that `dist` directory is created with `NgDemo` folder which contains the compiled angular app files:

    Sachin@02:10 PM[~/workspace/project/mojo_angular/NgDemo]$ ls
    README.md         angular.json      dist              e2e               node_modules      package-lock.json package.json      src               tsconfig.json     tslint.json
    Sachin@02:10 PM[~/workspace/project/mojo_angular/NgDemo]$

Next, we'll copy everything within the folder dist/ to a folder on the `public` directory in Mojolicious app.
The Mojo full app consists of `public` directory which is a static file directory (served automatically).
Copy Angular app compiled into `dist` to `public` directory of mojo app so that mojo will serve automatically.

    Sachin@02:13 PM[~/workspace/project/mojo_angular/NgDemo]$ cp dist/NgDemo ~/workspace/project/mojo_angular/mojo_angular_app/public/

Of course if this were a proper project, you could generate it to build in the public directory, or even build at start time using something like [Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack). Still this is convenient for this demo.

Finally, let's run the Mojo (hypnotoad) server to see if the Angular page is served as it was from the Angular server.

    Sachin@02:48 PM[~/workspace/project/mojo_angular/mojo_angular_app]$ hypnotoad -f script/mojo_angular_app
    [Sat Dec 15 14:49:03 2018] [info] Listening at "http://*:8080"
    Server available at http://127.0.0.1:8080
    [Sat Dec 15 14:49:03 2018] [info] Manager 40633 started
    [Sat Dec 15 14:49:03 2018] [info] Creating process id file "/Users/Sachin/workspace/project/mojo_angular/mojo_angular_app/script/hypnotoad.pid"
    [Sat Dec 15 14:49:03 2018] [info] Worker 40634 started
    [Sat Dec 15 14:49:03 2018] [info] Worker 40635 started
    [Sat Dec 15 14:49:03 2018] [info] Worker 40637 started
    [Sat Dec 15 14:49:03 2018] [info] Worker 40636 started

![mojolicious serving angular SPA](mojo_serving_angular.png)

Congratulations! we have served angular app with Mojolicious. Please note that the URL will be `http://localhost:8080/NgDemo/`.

## Integrating the Apps Further

To show how the applications can interact, we'll now build a simple demo to show an api call to a Mojolicious backend routes from the Angular frontend and display the result in Angular.
Since, this is not an Angular blog I will not go too deep explaining Angular; there are plenty of resources in internet for that.

### Create a new route in the Mojo App

Add a route `advent/2018/detail` in Mojolicious app class which just responds to http `get` request.
For some demo data, I'll just use the first articles from the 2018 Mojolicious advent calendar as a detail list.
In a full mojo app it is best to put routes methods in `AppName/Controller/SomeModule.pm`, but this is just for quick demo so we can use [hybrid routes](https://mojolicious.org/perldoc/Mojolicious/Guides/Growing#Simplified-application-class).

    $r->get('advent/2018/detail' => sub {
        my $self = shift;

        return $self->render(
            json =>
                [
                    {
                        title  => 'Welcome & MojoConf Recap',
                        day    => 1,
                        author => 'Joel Berger',
                    },
                    {
                        title  => 'Automatic Reload for Rapid Development',
                        day    => 2,
                        author => 'Doug Bell',
                    },
                    {
                        title  => 'Higher Order Promises',
                        day    => 3,
                        author => 'brain d foy',
                    },
                ],
            status => 200,
        );
    });

As a sidenote, you may have to allow [Cross Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) if the Angular app throws an error while accessing the mojo API endpoint.
In that case you may want to make use of the [`before_dispatch`](https://mojolicious.org/perldoc/Mojolicious/#before_dispatch) app hook:

    $self->hook(before_dispatch => sub {
        my $c = shift;
        $c->res->headers->header('Access-Control-Allow-Origin' => '*');
    });

But please note, in a real-world application `*` is defeating the security feature.

### Changes in Angular side

An Angular app's core code files reside in `src/app` directory.
I will be making changes to following 4 files under `src/app` directory and explain changes:

- app.module.ts
- app.component.ts
- app.component.html
- app.component.css

#### Include HttpClient Module

First include HttpClient Module in the `app.module.ts` file.
`app.module.ts` is a TypeScript module. As everywhere, modules are a way of organizing and separating code. Also, in Angular it helps control Dependency Injection, in this case we are injecting HttpClient module.
HttpClient module will be used later for making http request.

    Sachin@11:38 PM[~/workspace/project/mojo_angular/NgDemo/src/app]$ cat app.module.ts
    import { BrowserModule } from '@angular/platform-browser';
    import { NgModule } from '@angular/core';
    import { HttpClientModule } from '@angular/common/http';

    import { AppRoutingModule } from './app-routing.module';
    import { AppComponent } from './app.component';

    @NgModule({
        declarations: [
            AppComponent
        ],
        imports: [
            BrowserModule,
            AppRoutingModule,
            HttpClientModule
        ],
        providers: [],
        bootstrap: [AppComponent]
    })
    export class AppModule { }
    Sachin@11:38 PM[~/workspace/project/mojo_angular/NgDemo/src/app]$

Where I have added two lines above: `import { HttpClientModule } from '@angular/common/http';`
and added `HttpClientModule` to the list of imports.

#### Code app.component.ts to set MVC stage

Components are the most basic UI building block of an Angular app. An Angular app contains a tree of Angular components.
Component basically creates a separate MVC world which makes code management granular and easy.
The `@Component` decorator can pass in many types of metadata to a class particularly following 3 metadata specifiers are significant:

- `selector`: specifies which UI component it targets.
- `templateUrl`: html for that selector element and
- `styleUrl`: specifies one or more style files to be used for that html

`Component Class` sets up stage for two way data binding. In our case, it just makes an HTTP GET request to Mojo route we defined earlier, then binds the output to variable `adventDetail2018`. This is then available in the view (app.component.html) as well. This is two way data binding as the changes made in component class or in view is visible in both sides.

    Sachin@12:33 AM[~/workspace/project/mojo_angular/NgDemo/src/app]$ cat app.component.ts
    import { Component } from '@angular/core';
    import { HttpClient } from '@angular/common/http';

    @Component({
        selector: 'app-root',
        templateUrl: './app.component.html',
        styleUrls: ['./app.component.css']
    })
    export class AppComponent {
        title = 'Mojolicious Angular web app';
        adventDetail2018;
        // Inject HttpClient into your component
        constructor(private http: HttpClient) {}
        ngOnInit(): void {
            // Make the HTTP get request to mojolicious route
            this.http.get('http://localhost:8080/advent/2018/detail').subscribe(data => {
                this.adventDetail2018 = data;
            });
        }
    }
    Sachin@12:33 AM[~/workspace/project/mojo_angular/NgDemo/src/app]$

#### Modify app.component.html file to show data

Now we'll modify app.component.html file to show data fetched from the Mojolicious backend.
Replace the default template which was displaced earlier with our own html.
I have just looped through `adventDetail2018` variable, which consists of data from http get request, using `*ngFor` built in directive to form a `table`.

    Sachin@12:34 AM[~/workspace/project/mojo_angular/NgDemo/src/app]$ cat app.component.html
    <div style="text-align:left">
        <h1>
            Welcome to {{ title }}!
        </h1>
        <h3>Mojolicious Advent Calendar 2018 Detail:</h3>
        <table>
            <thead>
                <th>Day</th>
                <th>Title</th>
                <th>Author</th>
            </thead>
            <tbody>
                <!--Angular two way data binding in action-->
                <tr *ngFor="let d of adventDetail2018">
                    <td>{{d.day}}</td>
                    <td>{{d.title}}</td>
                    <td>{{d.author}}</td>
                </tr>
            </tbody>
        </table>
    </div>
    <router-outlet></router-outlet>

#### Add little bit of style for the table

I have also added a bare minimum style in `app.component.css` file to show its significance and how beautifully angular separates css away from html file.

    Sachin@12:34 AM[~/workspace/project/mojo_angular/NgDemo/src/app]$ cat app.component.css
    table, th, td {
        border: 1px solid black;
        border-collapse: collapse;
    }
    th, td {
        padding: 5px;
        text-align: left;
    }
    Sachin@12:34 AM[~/workspace/project/mojo_angular/NgDemo/src/app]$

#### Build the Angular app

Run `ng serve` command(as earlier) to see if angular app is looking good.
Then run `ng build --base-href=./` and copy `dist` folder content to mojolicious app's `public` directory as shown earlier.

## Try it out!

Finally run `hypnotoad` as shown earlier
Visit `localhost:8080/NgDemo` in browser to witness wedding of Mojolicious and Angular:

![final mojolicious serving angular SPA](final_mojo_angular_app.png)

That's all you need for simple single page app with angular and mojo. Take it further and see what is possible!

## Further Reading

This was just a quick example, if you're interested, keep going with these resourses:

- [Angular guide](https://angular.io/docs)
- [Angular tutorial](https://angular.io/tutorial)
- For more example code to see more Angular and Mojolicious in action, please have a look at my git repo:
[https://github.com/tryorfry/mojolicious-ng4](https://github.com/tryorfry/mojolicious-ng4)


