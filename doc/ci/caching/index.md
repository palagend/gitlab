# Caching dependencies

- What is cache default behavior and when it's enabled?
- What is artifacts default behavior and when it's enabled?
- Are artifacts always uploaded to GitLab?
- How to preserve cache between builds (like npm or bower packages, composer vendors etc.)?
- How to keep generated files from one stage to another?
- Create examples for common cache and artifacts use.

- Caches are disabled if not defined globally or per-job
- Caches are only available for all jobs in your .gitlab-ci.yml if enabled globally
- Caches defined per-job are only used either a) for the next run of that job, or b) if that same cache is also defined in a subsequent job of the same run
- Artifacts need to be enabled per job
- Artifacts are available for subsequent jobs of the same run
- Artifacts are always uploaded to GitLab (coordinator)

1.) Define a cache with the 'key: ${CI_BUILD_REF_NAME}' - so that builds of the e.g. master branch always use the same cache - during your 'build' step, e.g. for your '/node_modules' folder
2.) Define artifacts for the output of the 'build' step, e.g. the '/dist' folder
Your 'deploy' job during that run will then have the '/dist' folder to deploy somewhere
All 'build' jobs of later runs will then have the '/node_modules' folder and don't need to download, compile and install all the modules again.
Oh, and "Run" is the execution of your .gitlab-ci.yml script because of a commit, i think.

My goal is to set up shared cache so the installation part took less time and such a way tests run will take less time.

you can use any of the GitLab CI Variables as the cache key.

I thought the documentation should be more clear about the cache, the relation of cache keys and cache paths (relative/absolute). How to share cache between subsecuent builds / jobs, and how the cache artifacts are constructed and restored.

there is no such thing as "cache artifacts"! ;-)
You have one or more artifacts from a job in a stage of a ran, and (with my example) you have "a cache".
- Artifacts are created during a run (your whole .gitlab-ci.yml, e.g. after a commit) and can be used by the following JOBS of that very same currently active run.
- Caches can be used by following RUNS of that very same JOB (a script in a stage, like 'build' in my example) in which the cache was created (if not defined globally).

You can never expect the cache to be actually present (though you can expect that from artifacts), and it looks like in your case that's what happens: the cache got cleared. Probably because you're using shared runners that have some restrictions...
**I'm guessing if you were using your own runners, everything would work as expected.**

I was also expecting content created in one-stage and/or job to pass on to subsequent stages/jobs in the same run.

After trying a lot, all it needed following 3 lines at the top to get things working as expected.

cache:
  key: ${CI_BUILD_REF_NAME}
  untracked: true

caches are not supposed to pass files to subsequent stages of the same run, only to subsequent runs of the same stage. artifacts will be passed to subsequent stages of the same run, and not to subsequent runs of the same stage.
if you add those 3 lines, your basically globally caching (and restoring) all untracked files for every stage of every run. that works, but it's fugly as hell (and takes quite a bit longer).

Remember that artifacts are uploaded to the GitLab instance itself, while shared caches are uploaded to whatever you're using for them.

We do support caching of gem's and other file artifacts. There are tricks about file locations, but once you get the hang of it, it works well. See https://gitlab.com/gitlab-org/gitlab-ci-yml/blob/master/Ruby.gitlab-ci.yml for an example for Ruby. It's actually one of the sources for our new CI configuration templates!
But sometimes, you don't really want caching, you want artifacts. Caching is an optimization, but isn't guaranteed to always work, so you need to be prepared to regenerate any cached files in each job that needs them.

Artifacts, on the other hand, are guaranteed to be available. It's sometimes confusing because the name artifact sounds like something that is only useful outside of the build, like for downloading a final image. But artifacts are also available in between stages within a build. So if you "build" your application by downloading all the required modules, you might want to declare them as artifacts so that each subsequent stage can depend on them being there. There are some optimizations like declaring an expiry time so you don't keep artifacts around too long, and using dependencies to control exactly where artifacts are passed around. Again, complicated subject that is poorly documented. I'd be happy to help you figure it out for your use case (and then publish the learnings).

- Document good caching practices, including setting a constant cache key to re-use the cache across branches and jobs.
- Document how to cache gems and npm modules.
- Document what caches are good for (not guaranteed, best-efforts, local-only by default).
- Document how to use s3 to share cache between runners. (Admin)
- Document what artifacts are good for (guaranteed, stored on GitLab server).
- Document using artifacts for passing files between jobs within the same pipeline.
- Encourage artifact expiry for controlling disk usage.
- Document dependencies to minimize downloading artifacts.

The default caching scheme is: creates a cache key of $CI_BUILD_NAME/$CI_BUILD_REF_NAME.

As an aside, while this feels like it might be safe, it means merge requests get slow first builds, which is probably a bad developer experience. Of course having crazy build results would be a bad DX too.

## Make distributed cache to be shared between runners

> Works only for autoscaling setups.

https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/issues/1897

We have the cache from the perspective of the developers (who consumes a cache within the build) and the cache from the perspective of the runner.
Depending on which type of runner you are using, it can act differently. For example, in gitlab.com we use autoscaling runner, which can use an external S3 service to store your cache.
For the autoscaler runner, the cache key you define in gitlab-ci.yml is unique for the project. So during a single pipeline run (of one or multiple jobs), whoever uses the same cache key will get access to the same data, but they can't "share" in the same run data with each other (like a shared / networked folder).
See more details for the autoscaler configuration: https://docs.gitlab.com/runner/install/autoscaling.html

i'm using static docker runner with S3 configured as cache backend. (all on promise installations: gitlab-ce, gitlab-ci-multi-runner, minio). i can scale it manually with docker-compose scale runners=3, which would just create 2 more docker containers on the same node.
i've already identified why the cache is not shared between runners and proposed solution. it's described in issue initial description.
if i do not use S3 cache backend i do understand that each docker runner runs it's own container and cache is just the docker volume. however S3 makes it possible to share cache with the runners as i've already outlined in issue initial description.

as for the projects sharing cache, it is already unique in the url, in the example i gave: project/133. so that part is okay, projects can't steal each-one's cache.

It is made this way, because I did assume that token is basically a key for specific runner configuration/architecture/and system. So basically cache created for one runner often will not be valid when used by different runner which can run on different architecture :) It's distributed, because it makes sense to use it this way for auto-scaling where we are sure that machine have the same configuration. So possibly is OK to use the same runner token on multiple machines as long as they have the same configuration, that way you will always have the build cache, that is valid to specific configuration.

This is also a reason why by default the cache is on per-job and per-branch basis, because we assume the worst default. It holds true when you for example you test against different golang/nodejs/ruby versions and vendored dependencies will most likely not work correctly. In most cases it's too restrictive and this is why you can configure cache key to relax that assumption.


[19:21] godfat
I am wondering, what if two jobs having the same cache key, but have different paths? would A cache still overwrites to B cache, even if paths don't match?

[19:23] tmaczukin
Yes. Cache at the end is zipped and stored as cache.zip file inside of /${key}/ directory.

[19:24] godfat
I think now we have default cache key, so we're sharing a lot of caches, which they could have different paths of course.
I am more wondering about restoring the cache for the job. do we only extract the paths, or just extract everything from the zip?

[19:29] nick
from memory, we extract everything in a fairly random order, and don't mind if archive A overwrites things in archive B

[19:42] tmaczukin
Yup, just like nick said. Zip file is extracted in job's workdir. What is in the file is created.
As for archiving - what was defined in the configuration is compressed into zip file, and this file is saved in the directory based on the cache_dir setting, project data and cache key (defined by user or created by default from job's name and git ref name). If some other job, with other cache configuration saved cache in the same zip file - it is overwritten. If user is using the S3 based shared cache, the file is additionally uploaded to S3 to an object based on cache key (so also two jobs with different paths but the same cache key will overwrite their cache).

[19:46] godfat
if cache would be extracted regardless paths, and the paths are only used for storing cache, then i could see why karma is failing that way. that being said, just remove the path cannot make sure that path is cleared.
the problem we're seeing right now is, we accidentally used both cache and artifacts for node modules. i just realized that and removed all paths pointing to node modules. however other old branches or so might still be uploading caches for node modules, which could overwrite artifacts... is that true? do we restore artifacts first or cache first?
if we always restore cache first, then artifacts, then it's probably fine



set the cache globally and use something like key: "$CI_BUILD_REF_NAME". Since default cache doesn't cache in between different stages.

the reason why it works the way it does is because the different steps might be executed on different machines. That is the beauty of Gitlab CI. This is why caching will need to be enabled "explicitly" for the folders/files you want to cache.

Nobody expects the directory to get cleaned before each stage. Maybe just give us an option to skip the cleaning?
the reason isn't that stages are being "cleaned" but that they are (potentially) executed on different runners.

Create files in one stage, and pass those files to subsequent stages in a guaranteed manner.
What we don't have is:
1. clear documentation how to do this,
1. efficient ways to use the same runner for subsequent jobs,
1. elegantly declare that these files should be passed within the pipeline, but not stored beyond that, nor made downloadable.
We have plans to solve (2) with sticky runner, and there's a good idea for (3) using the new artifact expiry, with a new declaration similar to "expire upon successful pipeline run".

The defaults are very, very, very conservative, because they are conservative they are not the best in terms of speed. I would say that this opens part of bigger problem that we should solve is to actually start preparing a guidelines to figuoring out and optimising builds.

One way or another for all possible solutions here, what I believe we need (even sooner that any other thing) is more detailed documentation for cache/artifacts maybe with common use-cases (many of them introduced in this issue).

it is meant to be used to speed up invocations of subsequent runs of a given job, by keeping things like dependencies (e.g. npm packages, Go vendor packages, etc.) so they don't have to be re-fetched from the public internet.

While I understand the cache can be abused to pass intermediate build results between stages, I'd rather use something that was designed for the purpose.

## Clearing the cache

## Cache vs artifacts

Should I use caching or artifacts? What fits best in my scenario?

Let's don't mix the caching with passing artifacts between stages.

Caching is not designed to pass artifacts between stages. You should never expect that you have the cache present. I will make the cache more configurable making it possible to cache between any jobs or any branch or anyway you want :) Cache is for runtime dependencies needed to compile the project: vendor/?

Artifacts are designed to upload some compiled/generated bits of the build. We will soon introduce the option (on by default) that artifacts will be restored in builds for next stages.

the artifacts could be fetched by any number of concurrent runners.

Caching is to speed-up the setup of build dependencies. There is no guarantee that the cache will be there.

That is what are the artifacts for - to pass data between builds. Of course they are exposed to be downloaded from UI, but since any job can run on different runners we need some central place to store them (you can later retry any build from web interface). The caching on the other hand allows you to speed up some operations on runner that you are using to run builds. The caching were never meant to be used to pass data between builds, since it doesn't make sense in this case.

I believe cache and artifacts should also be described more-use-like in documentation. I mean add big description so people won't confuse artifacts as they are defined by biggest CI engines now (Jenkins, Travis) – where they ARE defined as final product that can be downloaded/deployed/sent to HockeyApp etc.

I think it should be described as this:

- cache – temporary storage for project dependencies. [They are not useful for anything else, not for keeping intermediate build results for sure. I also think cache:key is useless here. All dependency managers can handle multiple versions of deps.]
- artifacts – stage results that will be passed between stages.

They are not stored locally, and even it they would be - this would not work for subsequent builds executed on different runners on different hosts. The point of artifacts is to have a one central place for them (GitLab CE/EE). If you don't want to have artifacts added to build - you just don't configure them. There is nothing stored by default. And if you want artifacts for a build, but only to share with next builds in pipeline - use expires_in.

there's also likely some confusion of build log that says it removes "build/" dir -- that is general checkout cleanup to remove untracked files. the cache or artifacts are unpacked after that step.

## Shared cache between different Runners

Use S3 like server for a shared cache dir

for docker based runners, as each instance cache is just docker volume mounted as /cache. you could if you use some docker volume driver (think nfs) to share /cache between runners.

 if you use concurrent runners your next stage could be
executed on another instance causing a cache missing issue.


## Disabling cache on specific jobs

```yaml
job:
  cache: {}
```

## Availability of the cache

using a single runner on a single machine. As such I don't have the issue where stage B might execute on a runner different from stage A, not guaranteeing the cache between stages. That will only work if the build goes from stage A to Z in the same runner/machine, otherwise, you might not have the cache available.


---

>
**Notes:**
- Introduced in GitLab Runner v0.7.0.
- Prior to GitLab 9.2, caches were restored after artifacts.
- From GitLab 9.2, caches are restored before artifacts.

`cache` is used to specify a list of files and directories which should be
cached between jobs. You can only use paths that are within the project
workspace.

**By default caching is enabled and shared between pipelines and jobs,
starting from GitLab 9.0**

If `cache` is defined outside the scope of jobs, it means it is set
globally and all jobs will use that definition.

Cache all files in `binaries` and `.config`:

```yaml
rspec:
  script: test
  cache:
    paths:
    - binaries/
    - .config
```

Cache all Git untracked files:

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

Cache all Git untracked files and files in `binaries`:

```yaml
rspec:
  script: test
  cache:
    untracked: true
    paths:
    - binaries/
```

Locally defined cache overrides globally defined options. The following `rspec`
