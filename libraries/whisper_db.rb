module Bifrost
  module WhisperDB

    # For a given Graphite metric label prefix, consult the Whisper
    # database files on disk to determine what the next level metric
    # hierarchies are.
    #
    # The motivation for this follows.  Suppose you have a collection
    # of metrics like this:
    #
    #     myapp.module1.thing1.count
    #     myapp.module1.thing1.mean
    #     myapp.module1.thing2.count
    #     myapp.module1.thing2.mean
    #     myapp.module2.thing1.count
    #     myapp.module2.thing1.mean
    #
    # That is, `module1` can process `thing1` and `thing2`, but
    # `module2` can only process `thing1`, but you want to write your
    # recipe to loop over all modules and produce just the graphs that
    # you need, without having to specifically code these module
    # restrictions into your cookbook.
    #
    # By invoking this method with a `label_prefix` of
    # `"myapp.module1"`, you would get back `["thing1", "thing2"]`,
    # while invoking it with `"myapp.module2"` would return only
    # `["thing1"]`.
    #
    # Similarly, you could obtain a list of all modules by invoking it
    # with a `label_prefix` of `"myapp"`.
    #
    # Note that the current implementation only returns the next level
    # if there are more metrics rooted at that hierarchy.  In our
    # example, the structure on disk would look like this:
    #
    #     myapp
    #     \- module1
    #     |   \- thing1
    #     |   |   \- count.wsp
    #     |   |   \- mean.wsp
    #     |   \- thing2
    #     |       \- count.wsp
    #     |       \- mean.wsp
    #     \- module2
    #        \- thing1
    #            \- count.wsp
    #            \- mean.wsp
    #
    # Note that `thing1` and `thing2` are always directories.  If
    # there were a metric whose complete label was, say
    # `myapp.module1.clicks`, (corresponding to the file-on-disk of
    # `"#{whisper_db_root}/myapp/module1/clicks.wsp"`), the value
    # "clicks" will **NOT** appear in the result array.
    #
    # @param label_prefix [String] The initial portion of a Graphite
    #   metric label, such as `"foo.bar.baz"`
    # @param whisper_db_root [String] The absolute path of the
    #   directory where all Whisper database files are stored, such as
    #   `"/opt/graphite/storage/whisper"`.  You probably have this in
    #   an attribute somewhere.
    def self.next_level_metrics(label_prefix, whisper_db_root)
      metric_path = label_prefix.split(".")  # "foo.bar.baz" => ["foo", "bar", "baz"]

      dir = File.join(whisper_db_root, *metric_path) # => "/opt/graphite/storage/whisper/foo/bar/baz"

      if Dir.exist?(dir)
        # The label prefix exists!
        Dir.entries(dir).select{|e|
          # Only keep entries that are themselves directories (and
          # thus have more metrics beyond)..
          Dir.exists?(File.join(dir, e))
        }.reject{|e|
          # ...But not the dot aliases
          ["..", "."].include?(e)
        }
      else
        # The metric hierarchy rooted at `label_prefix` doesn't exist.
        # This isn't necessarily an error, though, since the metrics
        # may not be there yet. That is, run chef-client again after
        # the expected metrics have started to flow and you'll find
        # them.
        []
      end
    end

  end
end
