PomLoader - A Maven Pom Loader
==============================

Simplify working with java dependencies.

You need to meet the following requirements:
 1. Running with jruby
 2. Mavenized Project

## HOWTO
 - Specify your java dependencies in a pom.xml (same as you would a java
maven project)
 - Add the following lines to an intializer or spec_helper
 - Smile because your java dependencies are loaded onto your classpath
when you start your app

#### Install
````ruby
gem install pom-loader
````

#### Usage
```ruby
require 'pom-loader'
pom_dir = File.expand_path("../../", __FILE__)
mvn = ENV['MVN2_EXE'] || 'mvn'
PomLoader.load(pom_dir: pom_dir, mvn_exe: mvn)
$! = nil # unset evil magic bit
```

--
PomLoader will cause the ruby process to:
 1. parse the pom.xml file
 2. figure out and load all jar dependencies.
 3. Setup the log4j context if target/classes/com/homeaway/log4j.xml exists
 4. Setup Java system properties for every property parsed from the jetty plugin system properties.

## Adding the Rake Task
We've provided a rake task that will gather/install all of your java dependencies for your jruby project.
Inside of your project's rakefile simply add:

```ruby
require 'pom-loader/tasks'
```

And now when you 'rake -T' you should see:
```
...
rake pom_loader:load      # Generate and gather all of the files required for PomLoader
...
```
## License

Apache License version 2.0


