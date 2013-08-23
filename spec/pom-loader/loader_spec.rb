require 'spec/spec_helper'

describe PomLoader::Loader do

  before(:each) { @pom_dir = File.expand_path('../../test-poms', __FILE__) }
  after(:each) { FileUtils.rm_rf("#{@pom_dir}/target", secure: true) }

  it 'should be able to be initialized with defaults' do
    expect{ PomLoader::Loader.new }.to_not raise_error
  end

  it 'should be able to be initialized with options' do
    loader = PomLoader::Loader.new(pom_dir: 'pom', mvn_repo_dir: 'repo', target_classes_dir: 'target', log4j_xml_file: 'log4j', mvn_exe: 'exe')
    loader.pom_dir.should eql 'pom'
    loader.mvn_repo_dir.should eql 'repo'
    loader.target_classes_dir.should eql 'target'
    loader.log4j_xml_file.should eql 'log4j'
    loader.mvn_exe.should eql 'exe'
  end

  it 'should be able to be able to build an effective pom' do
    loader = PomLoader::Loader.new(pom_dir: @pom_dir)
    loader.pom_dir.should end_with 'spec/test-poms'
    loader.build_effective_pom

    File.exist?("#{@pom_dir}/target/effective-pom.xml").should be_true

    effective_pom = Nokogiri::XML(File.open("#{@pom_dir}/target/effective-pom.xml"))
    effective_pom.css('project name').count.should eql 1

    # Doesn't work off the bat :(
    #expected_pom = Nokogiri::XML(File.open("#{@pom_dir}/expected-pom.xml"))
    #effective_pom.should eql expected_pom
  end

  it 'should be able to build a class path and download all of our jars' do
    loader = PomLoader::Loader.new(pom_dir: @pom_dir)
    loader.pom_dir.should end_with 'spec/test-poms'
    FileUtils.rm_rf("#{@pom_dir}/target", secure: true)
    FileUtils.rm_rf(loader.mvn_repo_dir, secure: true)
    loader.build_classpath

    File.exist?("#{@pom_dir}/target/build-classpath.txt").should be_true

    jar_count = 0
    File.readlines("#{@pom_dir}/target/build-classpath.txt").each do |line|
      line.split(':').each do |jar|
        File.exists?(jar).should be_true
        jar_count += 1
      end
    end

    jar_count.should eql 1
  end


  it 'should add jars to the class path' do
    loader = PomLoader::Loader.new(pom_dir: @pom_dir)
    loader.pom_dir.should end_with 'spec/test-poms'
    loader.build_classpath
    loader.add_jars_to_classpath

    $CLASSPATH.count.should eql 7 # may change based on local config
  end

  it 'should parse the effective pom' do
    loader = PomLoader::Loader.new(pom_dir: @pom_dir)
    loader.pom_dir.should end_with 'spec/test-poms'
    loader.build_effective_pom
    loader.build_classpath
    loader.add_jars_to_classpath
    loader.parse_effective_pom

    # TODO: This pom doesn't have any systemProperty tags so this is a useless test
    # java.lang.System.getProperties.count.should eql 63
  end

  it 'should be able to load everything in one command' do
    loader = PomLoader::Loader.new(pom_dir: @pom_dir)
    loader.pom_dir.should end_with 'spec/test-poms'
    loader.load

    # Verify the loader is initialized
    loader.pom_dir.should_not be_nil
    loader.mvn_repo_dir.should_not be_nil
    loader.target_classes_dir.should_not be_nil
    loader.log4j_xml_file.should_not be_nil
    loader.mvn_exe.should_not be_nil


    # Verify we have an effective pom
    effective_pom = Nokogiri::XML(File.open("#{@pom_dir}/target/effective-pom.xml"))
    effective_pom.css('project name').count.should eql 1

    # Verify our build-classpath file is correct and our jars exist
    jar_count = 0
    File.readlines("#{@pom_dir}/target/build-classpath.txt").each do |line|
      line.split(':').each do |jar|
        File.exists?(jar).should be_true
        jar_count += 1
      end
    end
    jar_count.should eql 1

    # Verify our classpath has been modified.
    $CLASSPATH.count.should eql 7

    # Verify our systemProperties have been added.
    # java.lang.System.getProperties.count.should eql 63
  end
end

