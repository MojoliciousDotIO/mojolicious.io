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
        photo by [https://commons.wikimedia.org/w/index.php?curid=646036](https://commons.wikimedia.org/w/index.php?curid=646036)
        
data:
  bio: sachindangol
  description: 'Learn how to marry Mojolicious and Angular for building awesome web application'
---

# Mojolicious and Angular
[Angular](https://angular.io/) is arguably the best front-end web application framework which helps you build modern applications for the web, mobile, or desktop.

[Mojolicious](https://mojolicious.org/), a next generation web framework for the Perl programming language.
Mojolicious and Angular together can certainly build a next generation web framework.

At work, we have been using these two to build a very responsive, scalable and fantastic web apps. 
Mojolicious as a backend gives a lot of fun to work stuffs like Minion, Mojo::Dom, Test::Mojo, Mojoliious::Plugin::*, easy implementation of OpenAPI, OAuth, utility modules and of course CPAN.

One of the reasons you want to have this kind of web development set up is that front-end Angular developers and backend Mojolicious developers can work independently.

Angular is backend agnostic. Node.js Express is often used as backend for Angular. We love Perl and Mojolicious.

---

We will see how these two can be married to make a web application today.

I will be using auto-generated apps from both Mojolicious using [mojo](https://mojolicious.org/perldoc/Mojolicious/Commands) and Angular using [Angular CLI](https://angular.io/cli).

### Generate Mojolicious Full App
First I generate mojo full app using `mojo` CLI.

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

Mojolicious full-app is created. Start [hypnotoad](https://mojolicious.org/perldoc/Mojo/Server/Hypnotoad), a production web server.

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


### Generate Angular App:
Angular Version 7 is used for this demo, should work for version 4+. Demo on how to install Angular and CLI will be way too boring for this blog and there are plenty of resources for this in internet.

Let's use Angular CLI to generate a new app, `ng new app-name`.
Angular CLI is a command-line interface tool that you use to initialize, develop, scaffold, and maintain Angular applications.

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

Next start server with `ng serve` command.

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

Open browser to check Angular app:

![basic angular app](angular_app.png)

Note that this page's content is coming from `NgDemo/src/index.html` where `app-root` selector html is content coming from `NgDemo/src/app/app.component.html`. Later we will be modifying `app.component.html` file to show our own content instead of default angular logo and some links. 

## How to make Mojolicious app serve an Angular app?
##### a. Compile Angular app
`ng build` compiles an Angular app into an output directory named **dist/** at the given output path.
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

 Note that **dist** directory is created with `NgDemo` folder which contains compiled angular app files:

    Sachin@02:10 PM[~/workspace/project/mojo_angular/NgDemo]$ ls
    README.md         angular.json      dist              e2e               node_modules      package-lock.json package.json      src               tsconfig.json     tslint.json
    Sachin@02:10 PM[~/workspace/project/mojo_angular/NgDemo]$   

##### b. Copy everything within the folder dist/ to a folder on the `public` directory in Mojolicious app
Mojo full app consists of `public` directory which is a static file directory (served automatically).
Copy Angular app compiled into `dist/` to `public` directory of mojo app so that mojo will serve automatically. 

    Sachin@02:12 PM[~/workspace/project/mojo_angular/NgDemo]$ cd dist
    Sachin@02:13 PM[~/workspace/project/mojo_angular/NgDemo/dist]$ ls NgDemo
    Sachin@02:13 PM[~/workspace/project/mojo_angular/NgDemo/dist]$cp -R NgDemo ~/workspace/project/mojo_angular/mojo_angular_app/public/
    Sachin@02:13 PM[~/workspace/project/mojo_angular/NgDemo/dist]

##### c. Modify Mojo Application class to serve angular app:
Mojo Application class, `~/workspace/project/mojo_angular/mojo_angular_app/lib/MojoAngularApps.pm` in our demo, should be modified
to push compiled angular app directory to mojo's static paths list so that it is served automatically as well.

    package MojoAngularApp;

    use Mojo::Base 'Mojolicious';

    # This method will run once at server start       
    sub startup {
        my $self = shift;

        # Load configuration from hash returned by config file
        my $config = $self->plugin('Config');

        # Configure the application
        $self->secrets($config->{secrets});

        # Router                                          
        my $r = $self->routes;
    
        # serve angular SPA located at static page location                                                                              
        push @{$self->static->paths} => $self->home->child('public/NgDemo');

        # Normal route to controller                      
        $r->get('/')->to('example#welcome');
    }

    1;

Magic line above is:
    
    push @{$self->static->paths} => $self->home->child('public/NgDemo');

##### d. Run hypnotoad server to see if angular page is served

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

**Congratulations! we have served angular app with Mojolicious. Please note that the URL is the public route of mojo app `http://localhost:8080/NgDemo/`**

## Integrating the Apps Further
A simple demo to show an api call to Mojolicious routes from Angular and display in Angular. 
Since, this is not an Angular blog I will not go too deep explaining Angular; there are plenty of resources in internet for that.

#### 1. Create a new route in Mojolicious App:
Add a route `advent/2018/detail` in Mojolicious APP class(`lib/MojoAngularApp.pm`) which just responds to http `get` request 
with first 3 Mojolicious advent 2018 detail list.

    # in full mojo app it is best to put routes methods in
    # AppName/Controller/SomeModule.pm. This is just for quick demo.
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

You may have to allow Cross Origin Resource Sharing(CORS) if Angular app throws an error while accessing the mojo API endpoint.
In that case you may want to make use of awesome `before_dispatch` app hook like bellow:

    $self->hook(before_dispatch => sub {
        my $c = shift;
        $c->res->headers->header('Access-Control-Allow-Origin' => '*');
    });

In a real-world application `*` is defeating the security feature.

#### 2. Changes in Angular side:
An Angular apps core code files reside in `src/app` directory.
I will be making changes to following 4 files under `src/app` directory and explain changes:

- app.module.ts
- app.component.ts
- app.component.html
- app.component.css

##### First include HttpClient Module in app.module.ts file
`app.module.ts` is a [TypeScript](https://www.typescriptlang.org/docs/home.html) module. As everywhere, modules are a way of organizing and separating code. Also, in Angular it helps control Dependency Injection, in this case we are injecting HttpClient module.
HttpClient module is later required for making http request.

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

I have added two lines above: `import { HttpClientModule } from '@angular/common/http';`
and added `HttpClientModule` to the list of imports.

##### Code app.component.ts to set MVC stage
Components are the most basic UI building block of an Angular app. An Angular app contains a tree of Angular components.
Component basically creates a separate MVC world which makes code management so granular and easy.
`@Component` decorator can pass in many metadata to a class particularly following 3 metadata specifiers are significant:

- `selector`: specifies which UI component it targets.
- `templateUrl`: html for that selector element and
- `styleUrl`: specifies one or more style files to be used for that html

`Component Class` sets up stage for two way data binding. In our case, it just makes http get request to mojo route we defined earlier in mojo app class, binds the output to variable `adventDetail2008` which is then available in view (app.component.html) as well. This is two way data binding as the changes made in component class or in view is visible in both sides.

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

##### Modify app.component.html file to show data fetched from backend Mojolicious
Replace the default template(html) which was displaced earlier with our own html.
I have just looped through `adventDetail2018` variable, which consists of data from http get request, using `*ngFor` built in directive to form a `table` body.

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

##### app.component.css - Add little bit of style for the table. 
Added a bare minimum style in `app.component.css` file to show its significance and how beautifully angular separates css away from html file.

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

##### Run `ng serve` command(as earlier) to see if angular app is looking good.

##### Run `ng build --base-href=./` and copy `dist` folder content to mojolicious app's `public` directory as shown earlier

##### Finally run `hypnotoad` as shown earlier
Visit `localhost:8080/NgDemo` in browser to witness wedding of Mojolicious and Angular:

![final mojolicious serving angular SPA](final_mojo_angular_app.png)

**That's all you need for simple single page app with angular and mojo. Take it further and see what is possible!**

### Further Reading:
- [Angular guide](https://angular.io/docs)
- [Angular tutorial](https://angular.io/tutorial)
- For more example code to see more Angular and Mojolicious in action, please have a look at my git repo:
[https://github.com/tryorfry/mojolicious-ng4](https://github.com/tryorfry/mojolicious-ng4)
