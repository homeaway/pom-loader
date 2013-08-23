require 'spec/spec_helper'

describe PomLoader do
  specify { subject.should respond_to(:load) }

  it 'should load using specific fields' do
    loader = PomLoader.load(pom_dir: 'pom', mvn_repo_dir: 'repo', target_classes_dir: 'target', log4j_xml_file: 'log4j', mvn_exe: 'exe')
    loader.pom_dir.should eql 'pom'
    loader.mvn_repo_dir.should eql 'repo'
    loader.target_classes_dir.should eql 'target'
    loader.log4j_xml_file.should eql 'log4j'
    loader.mvn_exe.should eql 'exe'
  end


  it 'should be able to load a real project' do
    pom_dir = File.expand_path('../../test-poms', __FILE__)
    loader = PomLoader::load(pom_dir: pom_dir)
    loader.pom_dir.should end_with 'spec/test-poms'

    # Verify the loader is initialized
    loader.pom_dir.should_not be_nil
    loader.mvn_repo_dir.should_not be_nil
    loader.target_classes_dir.should_not be_nil
    loader.log4j_xml_file.should_not be_nil
    loader.mvn_exe.should_not be_nil


    # Verify we have an effective pom
    effective_pom = Nokogiri::XML(File.open("#{pom_dir}/target/effective-pom.xml"))
    effective_pom.css('project name').count.should eql 1

    # Verify our build-classpath file is correct and our jars exist
    jar_count = 0
    File.readlines("#{pom_dir}/target/build-classpath.txt").each do |line|
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
