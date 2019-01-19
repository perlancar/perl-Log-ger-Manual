package Log::ger::Manual::Tips;

# DATE
# VERSION

1;
# ABSTRACT: Tips when using Log::ger

=head1 AVOIDING MULTIPLE REINITS

This should not matter unless you need to load a lot of plugins (and/or outputs,
formatters, layouters, since these are all plugins too) *and* you have lots of
modules in your applications that use logging *and* you have loaded those
modules before initializing logging. And even then it should still be just a bit
more overhead. But here it goes.

When you use Log::ger in a package, e.g.:

 package MyApp;
 use Log::ger;

then C<MyApp> is added to the list of package targets. The list is consulted
whenever we need to reinitialize all targets, i.e. reinstall logging routines
for those targets.

Since by this time we have not added any outputs, then what Log::ger does is
just install a no-op subroutine C<log_fatal()>, C<log_error()>, and so on to the
target C<MyApp>. When user calls C<log_fatal()> inside this package, the output
will go nowhere.

Let's say you also log in another package:

 package MyApp::Component1;
 use Log::ger;

the same thing will happen: C<MyApp::Component> will have no-op logging
routines.

Now let's say in your main application, you do this:

 use MyApp;
 use MyApp::Component1;
 use Log::ger::Output 'Screen';

the C<use Log::ger::Output 'OUTPUTNAME'> line will install some hooks from
C<Log::ger::Output::OUTPUTNAME> to the list of hooks, B<then reinitializes all
existing targets.> In this case, the Screen output will install a hook in the
C<create_log_routine> phase that produces logger routines that prints to screen.
When reinitializing, Log::ger will reinstall these logger routines to the
C<MyApp> and C<MyApp::Component1> namespaces. So when later user calls
C<log_fatal()> in the C<MyApp> or C<MyApp::Component1> package, the log message
will be printed to screen.

Suppose later a C<use Log::ger::Output 'File'> statement is issued. The
reinitialization process will change all logging routines in all targets to
print to file instead. Logging is fast in Log::ger because Log::ger installs a
customized logging routine on each target, but as a consequence reinitialization
can take more time when there are lots of targets. This will become even slower
if you load lots of plugins in your main application:


For each C<use Log::ger::Output> or C<use Log::ger::Plugin> or C<use
Log::ger::Format> statement, a reinit will happen to potentially many targets.
Note that unless you have thousands of targets, all those reinits will still
happen in under one second. But to avoid reinit, you can either load Log::ger
plugins before adding lots of targets:

 use Log::ger::Output 'Screen';
 use Log::ger::Plugin 'Plugin1';
 use Log::ger::Plugin 'Plugin2';
 use Log::ger::Plugin 'Plugin3';
 use Log::ger::Plugin 'Plugin4';
 use Log::ger::Format 'Format1', {arg=>'value', ...};
 use MyApp;
 use MyApp::Component1;
 use MyApp::Component2;
 use MyApp::Component3;
 use MyApp::Component4;
 use MyApp::Component5;

or (the uglier way) tells the statements (but the last one) to not reinit:

 use MyApp;
 use MyApp::Component1;
 use MyApp::Component2;
 use MyApp::Component3;
 use MyApp::Component4;
 use MyApp::Component5;
 use Log::ger::Output {name=>'Screen', reinit=>0};
 use Log::ger::Plugin {name=>'Plugin1', reinit=>0};
 use Log::ger::Plugin {name=>'Plugin2', reinit=>0};
 use Log::ger::Plugin {name=>'Plugin3', reinit=>0};
 use Log::ger::Plugin {name=>'Plugin4', reinit=>0};
 use Log::ger::Format {name=>'Format1', conf=>{arg=>'value', ...}, reinit=>1}; # or just do not specify reinit, which defaults to 1
