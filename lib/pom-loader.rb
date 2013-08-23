# Copyright (c) 2013 HomeAway, Inc.
# All rights reserved.  http://www.homeaway.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'benchmark'
require 'nokogiri'

module PomLoader

  def self.load(options = {})
    loader = PomLoader::Loader.new(options)
    loader.load
  end

  class Loader
    attr_accessor :pom_dir, :mvn_repo_dir, :target_classes_dir, :log4j_xml_file, :mvn_exe, :loaded, :pom_changed_at

    # @param [Hash] options overrides default mvn pom settings
    # @option options [String] :pom_dir (Dir.pwd) The directory where your pom.xml file lives
    # @option options [String] :mvn_repo_dir (Dir.home + '/.m2/repository') The directory where your .m2 repository lives
    # @option options [String] :target_classes_dir (pom_dir + '/target/classes') The target classes directory
    # @option options [String] :log4j_xml_file ('') Optional log4j configuration
    # @option options [String] :mvn_exe ('mvn') the maven executable command
    #
    # note: mvn_repo_dir has absolutely no impact on anything.
    def initialize(options = {})
      @pom_dir = options[:pom_dir] || Dir.pwd
      @mvn_repo_dir = options[:mvn_repo_dir] || (Dir.home + '/.m2/repository')
      @target_classes_dir = options[:target_classes_dir] || (@pom_dir + '/target/classes')
      @log4j_xml_file = options[:log4j_xml_file] || "#{@target_classes_dir}/com/homeaway/log4j.xml"
      @mvn_exe = options[:mvn_exe] || ENV['MVN2_EXE'] || 'mvn'
    end

    # Load dependency jars onto classpath specified by a maven pom.xml file
    def load
      if File.exists? "#{pom_dir}/pom.xml"
        @pom_changed_at = File.ctime("#{pom_dir}/pom.xml")
        puts "Loading java environment from #{@pom_dir}/pom.xml"
        build_effective_pom
        build_classpath
        add_jars_to_classpath
        parse_effective_pom
        load_logger if File.exists? @log4j_xml_file
        @loaded = true
      else
        @loaded = false
        puts "Not loading java environment. pom dir=#{@pom_dir}"
      end
      self
    end

    def build_effective_pom
      time = Benchmark.realtime do
        effective_pom_path = "#{@pom_dir}/target/effective-pom.xml"
        if !File.exists?(effective_pom_path) || File.ctime(effective_pom_path) < @pom_changed_at
          process_output = `#{mvn_exe} -f #{@pom_dir}/pom.xml help:effective-pom -Doutput=#{effective_pom_path}`
          puts process_output unless $?.success?
        end
      end
      puts "Built effective-pom.xml in #{time}s"
    end

    def build_classpath
      time = Benchmark.realtime do
        build_classpath = "#{@pom_dir}/target/build-classpath.txt"
        if !File.exists?(build_classpath) || File.ctime(build_classpath) < @pom_changed_at
          process_output = `#{@mvn_exe} -f #{@pom_dir}/pom.xml dependency:build-classpath -DincludeTypes=jar -Dmdep.outputFile=#{build_classpath}`
          puts process_output unless $?.success?
        end
      end
      puts "Built build-classpath.txt in #{time}s"
    end

    def add_jars_to_classpath
      time = Benchmark.realtime do
        File.readlines("#{@pom_dir}/target/build-classpath.txt").each do |line|
          line.split(':').each do |jar|
            $CLASSPATH << jar
          end
        end

        $CLASSPATH << @target_classes_dir if Dir.exists? @target_classes_dir
      end
      puts "Added java paths to $CLASSPATH in #{time}"
    end

    def parse_effective_pom
      require_java
      time = Benchmark.realtime do
        pns = 'http://maven.apache.org/POM/4.0.0'
        pom_doc = Nokogiri::XML(File.open("#{@pom_dir}/target/effective-pom.xml"))
        pom_doc.xpath('//pom:systemProperty', 'pom' => pns).each do |n|
          name = n.xpath('pom:name', 'pom' => pns).first.text
          value = n.xpath('pom:value', 'pom' => pns).first.text
          puts "Adding System Property: #{name} value: #{value}"
          java.lang.System.setProperty name, value
        end
      end
      puts "Parsed effective-pom.xml in #{time}s"
    end

    def load_logger
      require_java
      time = Benchmark.realtime do
        puts 'adding log4j file ' + @log4j_xml_file
        org.apache.log4j.xml.DOMConfigurator.configure @log4j_xml_file
      end
      puts "Loaded log4j in #{time}s"
    end

    private

    def require_java
      raise 'Sorry you do not seem to be running on java so I cannot proceed.' unless RUBY_PLATFORM == 'java'
      require 'java'
    end
  end
end
