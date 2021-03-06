# Frequently (and perhaps infrequently) asked question (F.A.Q.)

## Q: What is this project

> A: This project aims to expose encryption operations (currently via GnuPG's
> PGP encryption applications) to logging daemons and/or user processes.
> Being designed as a *cyber defense* tool for server administrators and
> privacy concerned users of mobile devices, that wish for one more line of
> defiance against privacy violating attacks.

## Q: Why was this project built

> A: Encryption of arbitrary data or files is a common enough request that this
> tool was developed. This is not a partition encryption solution (often LUKS
> partitions are the *goto* for such Kernel level supported encryption where a
> file system can be mounted, read, and written to) instead this is a method of
> file by file and/or line by line encryption at the host OS's software layer
> that can either be saved to an appended file or sent to another process as a
> stream of encrypted data packets via another named pipe or service listening
> to the main script's stout.

## Q: What does this encryption scripted tool set do for me

> A: When properly implemented this project aims to reduce risks associated
> with remote server exploits leading to secondary attacks being easily carried
> out on that server's clients or admins by parsing plane text logs or other
> information that the server host contains that should not be available to
> unauthorized clients. Alternatively when properly implemented this project
> aims to make authorized access to encrypted logs a simple process. However,
> depending upon your inventiveness this project is capable of much more.

## Q: How is the code checked for bugs

> A: Both locally and remotely this repository is checked via a wonderful
> program, `shellcheck`, remote tests are facilitate via [CodeClimate.com](https://docs.codeclimate.com/docs/shellcheck)
> which is also how this project receives updated *badges* on the
> main [../ReadMe.md](../ReadMe.md) file. Note local checks when passed will *bump*
> the main script's sub-version and remote checks, auto-buils, are facilitated
> by [Travis-CI](https://travis-ci.org) you may click on the *`Badges`* on the
> main [../ReadMe.md](../ReadMe.md) file of this project to view build histories.

## Q: How do I checkout a previously working build

> A: Use the following steps for reverting your current working branch to a
> previous build step

```
git log --oneline
##... output example beguin
549623a Yet more attempts at fixes
##... output example end
```

> Find the commit ID, for this example we'll be using the above `549623a` ID from
> above to revert to.

```
git checkout 549623a
```

> Check the status and differences with the following to ensure that changes
> reverted are those that are wanted.

```
git status
git diff
```

> To find working vs non-working builds check the build
> [History](https://travis-ci.org/S0AndS0/Perinoid_Pipes/builds) provided by
> Travis-CI which will display compatible commit IDs to `checkout` to.

## Q: How do I find differances in commits

> A: Thankfully `git` makes this simple enough to accomplish between branches
> and commited changes

```
## Git diff from un-commited changes
git diff
## Git diff from last commit
git diff $(git log | grep commit | head -n2 | tail -n1 | awk '{print $2}')
## Git diff between branches
git diff master..branch_name
```

> Note if mutliple files changed within one commit, for example the `ReadMe.md`
> file, the following example commands will show how to reviel changes on single
> files for each of the above

```
## Git diff from un-commited changes
git diff ReadMe.md
## Git diff from last commit
git diff $(git log | grep commit | head -n2 | tail -n1 | awk '{print $2}') ReadMe.md
## Git diff between branches
git diff master..branch_name ReadMe.md
```

## Q: Do I *need* this project's services

> A: Are you a privacy conserned individual? Are you a sys-admin that must for
> some business reason handle information that should be restricted or
> confidential in some way? If `no` to either then you'll not likely need this
> project's services just yet. So far as the authors of this project can find
> evidence for, very few attacks escalate to the point that this project could
> be considered useful or *needed*. That said, based off the speed at which
> attacks are evolving, a tool like this may one day be the only thing left
> denying unauthorized access to a successful attacker. Else if `yes` consider
> this tool as an option (if GnuPG is allowed to you) that maybe used as yet
> another layer within your security modal.

## Q: What do you mean by, if GnuPG is allowed to you, statement above

> A: The authors of this project are not *experts* in happenings of
> international  *legalieze*, nor should you consider this advice within that
> realm, to put it simply; look up the laws of your own region in relation to
> the use of GnuPG. If you're allowed to use GnuPG then there's no restrictions
> as far as the authors of this project could find for use with this project
> on authorize hardware. However, if your within a region that can't make use
> of GnuPG then the authors would ask that you refrain from import for now.
> Note, this notice was added do to the recent activity on privacy *canneries*
> warning this projects' core authors of confidentiality violation reports being
> generated by third parties accessing what they where not authorized to access.

## Q: What does "project abandonment" mean

> A: You must have seen the licensing modification on the forums that this
> project's core authors has advertised it's self on. In short it means at any
> point in the future (unless a signed message fitting this project's core
> author's writing style is posted there) that this project may have it's
> licensing for documentation modified such that certain things no longer need
> be included in derivative works. Abandonment as defined by that authorized
> post is any time longer than ninety six (96) hours after the last signed
> push by core authors to this project's public code repository. This is to
> guaranty further *freedoms* of this project are implemented if at some
> point in the future this project's core authors either finish work on it or
> are no longer able to work on this project. This does **not** mean that the
> core authors of this project *plan* on abandoning this project, only that
> they've, as fully as possible, planed for events that may cause core authors
> to no longer be able to maintain this current project's code or documentation.

## Licensing notice for this file

```
    Copyright (C) 2016 S0AndS0.
    Permission is granted to copy, distribute and/or modify this document under
    the terms of the GNU Free Documentation License, Version 1.3 published by
    the Free Software Foundation; with the Invariant Sections being
    "Title page". A copy of the license is included in the directory entitled
    "License".
```

[Link to title page](Contributing_Financially.md)

[Link to related license](../Licenses/GNU_FDLv1.3_Documentation.md)
