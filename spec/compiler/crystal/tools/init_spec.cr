require "spec"
require "yaml"
require "compiler/crystal/tools/init"

def describe_file(name, &block : String ->)
  describe name do
    it "has proper contents" do
      block.call(File.read("tmp/#{name}"))
    end
  end
end

def run_init_project(skeleton_type, name, dir, author, email, github_name)
  Crystal::Init::InitProject.new(
    Crystal::Init::Config.new(skeleton_type, name, dir, author, email, github_name, true)
  ).run
end

module Crystal
  describe Init::InitProject do
    `[ -d tmp/example ] && rm -r tmp/example`
    `[ -d tmp/example_app ] && rm -r tmp/example_app`

    run_init_project("lib", "example", "tmp/example", "John Smith", "john@smith.com", "jsmith")
    run_init_project("app", "example_app", "tmp/example_app", "John Smith", "john@smith.com", "jsmith")
    run_init_project("lib", "example-lib", "tmp/example-lib", "John Smith", "john@smith.com", "jsmith")
    run_init_project("lib", "camel_example-camel_lib", "tmp/camel_example-camel_lib", "John Smith", "john@smith.com", "jsmith")
    run_init_project("lib", "example", "tmp/other-example-directory", "John Smith", "john@smith.com", "jsmith")

    describe_file "example-lib/src/example-lib.cr" do |file|
      assert file.includes?("Example::Lib")
    end

    describe_file "camel_example-camel_lib/src/camel_example-camel_lib.cr" do |file|
      assert file.includes?("CamelExample::CamelLib")
    end

    describe_file "example/.gitignore" do |gitignore|
      assert gitignore.includes?("/.shards/")
      assert gitignore.includes?("/shard.lock")
      assert gitignore.includes?("/libs/")
      assert gitignore.includes?("/.crystal/")
    end

    describe_file "example_app/.gitignore" do |gitignore|
      assert gitignore.includes?("/.shards/")
      assert !gitignore.includes?("/shard.lock")
      assert gitignore.includes?("/libs/")
      assert gitignore.includes?("/.crystal/")
    end

    describe_file "example/LICENSE" do |license|
      assert license =~ %r{Copyright \(c\) \d+ John Smith}
    end

    describe_file "example/README.md" do |readme|
      assert readme.includes?("# example")

      assert readme.includes?(%{```yaml
dependencies:
  example:
    github: jsmith/example
```})

      assert readme.includes?(%{TODO: Write a description here})
      assert !readme.includes?(%{TODO: Write installation instructions here})
      assert readme.includes?(%{require "example"})
      assert readme.includes?(%{1. Fork it ( https://github.com/jsmith/example/fork )})
      assert readme.includes?(%{[jsmith](https://github.com/jsmith) John Smith - creator, maintainer})
    end

    describe_file "example_app/README.md" do |readme|
      assert readme.includes?("# example")

      assert !readme.includes?(%{```yaml
dependencies:
  example:
    github: jsmith/example
```})

      assert readme.includes?(%{TODO: Write a description here})
      assert readme.includes?(%{TODO: Write installation instructions here})
      assert !readme.includes?(%{require "example"})
      assert readme.includes?(%{1. Fork it ( https://github.com/jsmith/example_app/fork )})
      assert readme.includes?(%{[jsmith](https://github.com/jsmith) John Smith - creator, maintainer})
    end

    describe_file "example/shard.yml" do |shard_yml|
      parsed = YAML.parse(shard_yml)
      assert parsed["name"] == "example"
      assert parsed["version"] == "0.1.0"
      assert parsed["authors"] == ["John Smith <john@smith.com>"]
      assert parsed["license"] == "MIT"
    end

    describe_file "example/.travis.yml" do |travis|
      parsed = YAML.parse(travis)

      assert parsed["language"] == "crystal"
    end

    describe_file "example/src/example.cr" do |example|
      assert example == %{require "./example/*"

module Example
  # TODO Put your code here
end
}
    end

    describe_file "example/src/example/version.cr" do |version|
      assert version == %{module Example
  VERSION = "0.1.0"
end
}
    end

    describe_file "example/spec/spec_helper.cr" do |example|
      assert example == %{require "spec"
require "../src/example"
}
    end

    describe_file "example/spec/example_spec.cr" do |example|
      assert example == %{require "./spec_helper"

describe Example do
  # TODO: Write tests

  it "works" do
    false.should eq(true)
  end
end
}
    end

    describe_file "example/.git/config" { }

    describe_file "other-example-directory/.git/config" { }
  end

  describe Init do
    it "prints error if a directory already present" do
      Dir.mkdir_p("#{__DIR__}/tmp")

      assert `bin/crystal init lib "#{__DIR__}/tmp" 2>/dev/null`.includes?("file or directory #{__DIR__}/tmp already exists")

      `rm -rf #{__DIR__}/tmp`
    end

    it "prints error if a file already present" do
      File.open("#{__DIR__}/tmp", "w")

      assert `bin/crystal init lib "#{__DIR__}/tmp" 2>/dev/null`.includes?("file or directory #{__DIR__}/tmp already exists")

      File.delete("#{__DIR__}/tmp")
    end

    it "honors the custom set directory name" do
      Dir.mkdir_p("tmp")

      assert `bin/crystal init lib tmp 2>/dev/null`.includes?("file or directory tmp already exists")

      assert !`bin/crystal init lib tmp "#{__DIR__}/fresh-new-tmp" 2>/dev/null`.includes?("file or directory tmp already exists")

      assert `bin/crystal init lib tmp "#{__DIR__}/fresh-new-tmp" 2>/dev/null`.includes?("file or directory #{__DIR__}/fresh-new-tmp already exists")

      `rm -rf tmp #{__DIR__}/fresh-new-tmp`
    end
  end
end
