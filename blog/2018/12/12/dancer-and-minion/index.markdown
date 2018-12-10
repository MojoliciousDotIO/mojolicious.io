---
title: Day 12: Using Minion in Dancer Apps
disable_content_template: 1
tags:
    - advent
    - development
    - dancer
    - minion
author: Jason Crome
data:
  bio: cromedome
  description: 'Overview of how to use Minion from within a Dancer application.'

---

At `$work`, we have built an API with Dancer that generates PDF documents and XML files. This API is a critical component of an insurance enrollment system: PDFs are generated to deliver to the client in a web browser 
immediately, and the XML is delivered to the carrier as soon as it becomes available. Since the XML often takes a significant amount of time to generate, the job is generated in the background so as not to tie up the 
application server for an extended amount of time. When this was done, a homegrown process management system was developed, and works by `fork()`ing a process, tracking its pid, and hoping we can later successfully
reap the completed process. 

There have been several problems with this approach:
- it's fragile
- it doesn't scale
- it's too easy to screw something up as a developer

In 2019, we have to ramp up to take on a significantly larger workload. The current solution simply will not handle the amount of work we anticipate needing to handle. Enter Minion.

*Note:* The techniques used in this article work equally well with Dancer or Dancer2.

---

## Why Minion?

We looked at several alternatives to minion, including [beanstalkd](https://beanstalkd.github.io/) and [celeryd](http://www.celeryproject.org/). Using either one of these meant involving our already over-taxed
infrastructure team, however; using Minion allowed us to use expertise that my team already has without having to burden someone else with assisting us. From a development standpoint, using a product that
was developed in Perl gave us the quickest time to implementation. 

Scaling our existing setup was near impossible. It's not only not easy to get a handle on what resources are consumed by processes we've forked, but it was impossible to run the jobs on more than one server. 
Starting over with Minion also gave us a much needed opportunity to clean up some code in sore need of refactoring. With a minimal amount of work, we were able to clean up our XML rendering code and make it work
from Minion. This cleanup allowed us to more easily get information as to how much memory and CPU was consumed by an XML rendering job. This information is vital for us in planning future capacity.

## Accessing Minion

## Creating Jobs

## Creating the Job Queue Worker

## Monitoring the Workers

## Outcome

Within about a two-week timespan, we went from having zero practical knowledge of Minion to having things up and running. We've made some refinements and improvements along the way, but the quick turnaround
is a true testament to the simplicity of working with Minion. 

We now have all the necessary pieces in place to scale our XML rendering both horizontally and vertically: thanks to Minion, we can easily run XML jobs across multiple boxes, and can more efficiently run 
more jobs concurrently on the same hardware as before. This setup allows us to grow as quickly as our customer base does.

## Further Reading

Dancer
Dancer2
Minion

