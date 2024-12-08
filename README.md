# PulsarOS

    /*****                                                  /******   /****
    |*    *|  |*   |  |*       ****     **    *****        |*    |  /*    *
    |*    *|  |*   |  |*      /*       /* *   |*   |      |*    |  |*
    |*****/   |*   |  |*       ****   /*   *  |*   /     |*    |   ******
    |         |*   |  |*           |  ******  *****     |*    |         |
    |         |*   |  |*       *   |  |*   |  |*  *    |*    |   *     |
    |          ****    *****    ****  |*   |  |*   *   ******    *****

A highly experimental version of [QuasarOS](https://github.com/quantum9innovation/QuasarOS) optimized for servers

## Development

Most development happens on other branches (and there will likely be a lot of them at any given time). Take a look at some others for a sampling of the latest experiments. `main` can be considered (relatively) stable.

## About

As this repository is nowhere near a finished state, I would recommend subscribing to releases, so you can receive a GitHub notification when the first stable release is ready. You're probably wondering, however, what and perhaps *why* this is. Here's a little bit of context …

As part of my journey into the dangerous, mind-bending terrain of purely functional programming and hyper-abstract quasi-philosophical mathematical ideas (see e.g. [category theory](https://en.wikipedia.org/wiki/Category_theory) and [topos theory](https://en.wikipedia.org/wiki/Topos)), I discovered [NixOS](https://nixos.org/). What is NixOS?

Unlike traditional operating systems which rely on non-deterministic package management mechanisms compromised by a myriad of internal states, Nix takes a declarative approach to configuring the entire operating system. It is a Linux distribution that ships with its own package manager that installs packages in a determinstic way by building them in isolation using pure functions known as "derivations."

In NixOS, there is no state. The entire system is derived from a handful of configuration files, which build the system in its entirety. The same configuration can be deployed across multiple machines[^1] and you get identical systems (:thinking: hmmm this sounds like something you might want in a server, right?).

As a Haskell addict, my brain was severely warped from the study of abstraction, and I began to examine some potential theories related to the abstraction of NixOS. You see, NixOS is really an abstraction on top of the Linux kernel. Unlike other distributions, which rely on internal state and therefore are not fully abstracted, NixOS specifies a language for building an operating system.

Taking this a bit further, we can abstract the Nix system configuration by creating a pure function ("derivation") that builds the standard configuration to build the system. Yes, we're talking about a derivation to build a derivation to build an operating system. At this point, if you have not been exposed to the pinnacle of abstraction that is category theory, you might want to stop reading.

This abstraction on top of NixOS allows for a custom Linux distribution to be built on top of NixOS. This distribution can ship with a series of default system configurations and packages, which can then be further customized by a user configuration, thereby further abstracting the already-abstracted NixOS configuration.

Of course, the choice of what those default system settings should be is highly personal. In the case of a server, however, there are a few "good" choices and a lot of others that depend on the specific use case. PulsarOS gives users this ability to customize on top of a solid server framework with good defaults built in. This is possible because it exports not a system configuration but a morphism which transforms an object of type user configuration to an object of type system configuration[^2].

To reach the pinnacle of abstraction, you must complete one more step. Both PulsarOS and the server configuration must be deployed to remote version-controlled repositories, which can then be used as inputs to the Nix derivation that builds the system, allowing for your entire system to be configured from afar (via git). This leaves you with a dead-simple effective system configuration that lives on your local machine. This configuration merely pulls in the server configuration and feeds it into the PulsarOS system builder, also pulled over the network.

What this means in practice is that server-specific settings like the device hostname and other identifying details (server configuration) can be stored in a separate repository from the collection of default system settings (PulsarOS). Of course, this is a highly experimental and probably quixotic idea, which is precisely why I had to test it.

PulsarOS is more stable than its user-focused counterpart (and the original testing ground for the Nix-based *nix OS) QuasarOS, since this is meant to be a good base for servers, but that doesn't mean that bleeding edge updates (and occasional breakages) will not be incorporated at warp speed.

[^1]: Assuming identical hardware; in reality, you need a special hardware configuration for each machine.

[^2]: It also allows for custom user configurations to be injected into the build process to take into account differences between e.g. hardware configuration across devices.
