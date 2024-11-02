# Verifies that find_executable's specs match the behavior of Process.run.
# This doesn't actually test find_executable, only takes all the test cases
# directly from spec/std/process/find_executable_spec.cr and checks that
# *they* match what the OS actually does when finding an executable for the
# purpose of running it.

require "spec"
require "digest/sha1"
require "../support/env"
require "../support/tempfile"
require "../std/process/find_executable_spec"

describe "Process.run" do
  test_dir = Path[SPEC_TEMPFILE_PATH] / "manual_find_executable"
  base_dir = Path[test_dir] / "base"
  path_dir = Path[test_dir] / "path"

  around_all do |all|
    Dir.mkdir_p(test_dir)

    exe_names, non_exe_names = FIND_EXECUTABLE_TEST_FILES
    (exe_names + non_exe_names).each do |name|
      Dir.mkdir_p((base_dir / name).parent)
      File.write(base_dir / name, "#!bad_executable/#{name.inspect}")
    end
    exe_names.each do |name|
      File.chmod(base_dir / name, 0o755)
    end

    with_env "PATH": {ENV["PATH"], path_dir}.join(Process::PATH_DELIMITER) do
      Dir.cd(base_dir) do
        all.run
      end
    end

    FileUtils.rm_r(test_dir.to_s)
  end

  find_executable_test_cases(base_dir).each do |(command, exp)|
    if exp
      it "runs '#{command}' and fails" do
        expect_raises File::NotFoundError do
          Process.run(command)
        end
      end
    else
      it "fails to run '#{command}'" do
        expect_raises IO::Error do
          Process.run(command)
        end
      end
    end
  end
end
