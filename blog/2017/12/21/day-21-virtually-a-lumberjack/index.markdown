---
title: "Day 21: Virtual(ly a) Lumberjack"
tags:
  - advent
  - 'non-web'
author: CandyAngel
images:
  banner:
    src: '/static/vr.jpg'
    alt: 'Woman wearing VR goggles outside'
    data:
      attribution: |-
        [Image](https://www.pexels.com/photo/sky-woman-clouds-girl-123335/) by Bradley Hook, in the Public Domain.
data:
  bio: candyangel
  description: Using the Mojo toolkit to help reverse-engineer HMDs
---
What do you do when you want to split up a stream of data in real-time while
giving the user instructions?

This is just what I wanted to do to aid in reverse-engineering the USB
protocol of Virtual Reality devices known as Head Mounted Displays (HMD), for
the [OpenHMD](http://www.openhmd.net/) project.

HMDs are used to create virtual reality environments. When worn, two slightly
different images are drawn to each side of the screen, with each side visible
to only one eye. The imitates binocular vision and creates an image with a
feeling of depth. By tracking the rotation of the unit, the user can then look
around this environment.

The recent resurge of Virtual Reality devices can be attributed to the Rift
DK1, released by Oculus in March 2013.

By logging the packets generated during each movement, we can compare the
content of each log to identify which bytes are related to which action. Such
movements include roll (tilting head side-to-side), pitch (looking up and
down) and yaw (turning left/right). Though position isn't tracked, we also
look for sway (left-right translation), surge (back and forth) and heave (up
and down) information as this is used in combination with the other values for
accurate tracking of rotation.

Mojo is an amazing toolkit for web development, as shown in previous
calendar entries, but using components of it can also solve problems in other
non-web spaces like these. Why use Mojo for this? Because it makes it *easy*.
---

## Down By The Riverside

First of all, we need the stream of data.
Initially, I used `tshark` for this, though another member of the OpenHMD team
built another application, OpenHMD-Dumper, which has both a device selection
interface and opens the device to read the packets, which makes this much
easier.
Doing so allows us to ask others who have HMDs to send us these logs, so we
can add driver support for devices none of the team have access to!
Otherwise, we use something else to open the device and read data and `tshark`
to capture and output the packet data.

    tshark -i usbmon1 -Y 'usb.src == "1.22.1"' -T fields -e usb.capdata

You may need to change your buffering to line-mode. You can do so by prefixing
`stdbuf -oL` like so:

    stdbuf -oL tshark ...

This (and OpenHMD-Dumper) will output data that looks like this:

    20:d6:00:1a:e0:4a:fe:d5:ff:12:00:66:00:be: ...
    20:c2:00:3c:e0:16:fe:d1:ff:04:00:62:00:d5: ...
    20:c2:00:3c:e0:16:fe:d1:ff:04:00:62:00:d5: ...

## Pretty Good Mojo

What we are going to do is get our Mojo-powered script to read this data and
output it to a PGM file.
PGM is an image format that can be created using plain text files and is
pretty much perfect for our use as we can see it both visually and easily
manipulate it with standard \*nix tools like *cut*, *head* and *sed*.

    #!/usr/bin/env perl
    use Mojo::Base '-base';

    use Mojo::Asset::File;
    use Mojo::IOLoop;
    use Mojo::IOLoop::Stream;

    use Mojo::Loader 'data_section';

    has file_count => 0;

    has file  => sub { shift->file_start('0_START.pgm') };
    has loop  => sub { Mojo::IOLoop->singleton };
    has stdin => sub { Mojo::IOLoop::Stream->new(\*STDIN)->timeout(0) };

    __PACKAGE__->new->main;

    sub main {
      my $self = shift;
      $self->stdin->on(read => sub { $self->stdin_read(@_) });
      $self->stdin->start;
      $self->loop->start unless $self->loop->is_running;
    }

    sub file_start {
      my ($self, $path) = @_;
      $self->file_count($self->file_count + 1);
      return Mojo::Asset::File->new(path => $path)->cleanup(0)->add_chunk(
        data_section(__PACKAGE__, 'pgm_header'),
      );
    };

    sub stdin_read {
      my ($self, $stream, $bytes) = @_;

      foreach my $packet (split /\n/, $bytes) {
        my $chunk = join ' ', (
          map { sprintf '%03i', hex($_) } split /:/, $packet
        );
        $self->add_chunk($chunk . "\n");
      }
    }

    __DATA__

    @@ pgm_header
    P2
    00000000 00000000
    255

This script will create 0_START.pgm, add a PGM header to it (which will need
fixing later) and writes the bytes it receives from STDIN into that file in
the correct format.

We have used various bits from the Mojolicious framework to achieve this.
[Mojo::Loader](http://mojolicious.org/perldoc/Mojo/Loader) lets us put our PGM
header separate from the rest of the code, just like an inline template for a
Lite app.
Since it is usually used to receive file uploads,
[Mojo::Asset::File](http://mojolicious.org/perldoc/Mojo/Asset/File) gives us
even simpler file creation and append mechanics than
[Mojo::File](http://mojolicious.org/perldoc/Mojo/File), for outputting the
re-formatted data input.
We do have to tell Mojolicious not to *cleanup* the file once it is done with
it, though this is small price to pay!
The heavier price is the frowns of disapproval in IRC for such (ab)use.. :)

[Mojo::IOLoop](http://mojolicious.org/perldoc/Mojo/IOLoop) and
[Mojo::IOLoop::Stream](http://mojolicious.org/perldoc/Mojo/IOLoop/Stream) give
us a nice callback interface for reading STDIN.
This doesn't seem too important right now, but the next stage will show why.
It allows us to direct the information coming in from STDIN while we instruct
the user which motion we want them to make with the HMD.

## I bid you.. move!

Let's add some instructions to be shown to the user.
To do this, we can just add in another section like *pgm_header*:

    @@ instructions
    1 Prepare for instructions, cherished aide!
    3 Steady

    2 Prep Yaw
    5 Start Yaw
    1 Stop Yaw
    3 Steady

    2 Prep Pitch
    5 Start Pitch
    1 Stop Pitch
    3 Steady

    2 Prep Roll
    5 Start Roll
    1 Stop Roll
    3 Steady

    2 Prep Sway
    5 Start Sway
    1 Stop Sway
    3 Steady

    2 Prep Surge
    5 Start Surge
    1 Stop Surge
    3 Steady

    2 Prep Heave
    5 Start Heave
    1 Stop Heave
    3 Steady

    0 The End Of Instructions. Thank you, generous one!

This format is very simple.
Leading number is how many seconds to wait on this instruction before moving
to the next one.
The text is what is output to the user.
We also use it to get the name of the file to create.

This could be formatted in a lot more of a structured way (e.g. YAML), but
this works fine for our purpose!

Let's make the instructions get loaded in, skipping any empty lines:

    has instructions => sub {[
      map {[split / /, $_, 2]}
      grep { length $_ }
      split /\n/, data_section(__PACKAGE__, 'instructions')
    ]};

And add a method which progresses us through the script:

    sub instruction_show {
      my $self = shift;

      my $instruction = shift @{$self->instructions};
      return $self->loop->stop_gracefully unless defined $instruction;

      say $instruction->[1];
      $self->loop->timer(
        $instruction->[0] => sub { $self->instruction_show },
      );

      $self->loop->timer($instruction->[0] / 2, sub {
        my $type = (split / /, $self->instructions->[0][1])[1];
        my $file_count = $self->file_count;
        my $path = sprintf '%i_%s.pgm', $file_count, uc $type;
        $self->file( $self->file_start($path) );
      }) if $instruction->[1] eq 'Steady';
    }

As you can see, we ask the loop to stop gracefully when there are no more
instructions.
Otherwise, we output the instruction and then schedule the next instruction
to be done in the amount of seconds we specified in the script.


If the action is to steady the HMD, we know we are going to start another
action shortly so, in half of the wait time, we start a new file.
This should mean that the end and start of each file, the HMD is not moving
(much).

Then we need to start walking through this script by adding this before
starting the event loop in *main*:

    $self->loop->timer(0 => sub { $self->instruction_show });

Running this now prompts the user to move the HMD while outputting the packet
data in an image named after the movement that image represents!

## Get Your Head(er) Checked

As mentioned, the PGM header is broken as it is supposed to contain the number
of rows and columns in the image, but this isn't known in advance.
We put an 8 character per value placeholder there and use this small shell
script to fix it up:

    #!/bin/sh

    FILE="$1";

    WIDTH=$(printf "%08d" $(tail -n+5 "$FILE" | head -n1 | tr -cd ' ' | wc -c));
    HEIGHT=$(printf "%08d" $(echo $(wc -l "$FILE" | cut -f1 -d' ') - 4 | bc));

    echo $WIDTH  | dd of="$FILE" bs=1 seek=3  count=8 conv=notrunc
    echo $HEIGHT | dd of="$FILE" bs=1 seek=12 count=8 conv=notrunc

Now these are valid PGM images and we can open them to see the data stream!

![Section of Yaw PGM](yaw.png)

(The above has been rotated and flipped, the original image is a thin
"waterfall".)

Some parts are immediately obvious.
Very smooth gradients next to larger smooth blocks or gradients hints at a
high-precision timer, which tend to be 32 bits (4 bytes) wide.
This can be seen at the top of the example.

Other aspects are only noticeable when compared to the other movements.
The simple file format makes it very easy to graph the data with gnuplot.
In the worst/simple case scenario, you can simply graph at each offset and
various sizes until you see a (rough) sine wave, indicating you've got the
right offset and number of bytes for that part of the puzzle!

## Moving On To Greater Things

This tool could easily be improved (and will be, when it is next called upon).
For example, both the extraction and fixing of the headers could be made into
commands, as demonstrated in
[Day 6](https://mojolicious.io/blog/2017/12/06/day-6-adding-your-own-commands/).

It could also be made into a proper web application where the user can select
the action they want to do and an animation shows the movement that is wanted
(not everyone is familiar with nautical terms after all!).
Perhaps even with a device select?
A UI that allows the user to select the offset, size and unpack method and
render the graphs as appropriate could cut down the time to analyse.
Better yet, if it could detect which combinations result in a rough sine wave,
it could narrow down and present the user with likely candidates for each
movement..

.. but those are improvements for another day!
