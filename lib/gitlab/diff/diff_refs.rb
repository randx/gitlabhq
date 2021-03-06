module Gitlab
  module Diff
    class DiffRefs
      attr_reader :base_sha
      attr_reader :start_sha
      attr_reader :head_sha

      def initialize(base_sha:, start_sha: base_sha, head_sha:)
        @base_sha = base_sha
        @start_sha = start_sha
        @head_sha = head_sha
      end

      def ==(other)
        other.is_a?(self.class) &&
          shas_equal?(base_sha, other.base_sha) &&
          shas_equal?(start_sha, other.start_sha) &&
          shas_equal?(head_sha, other.head_sha)
      end

      alias_method :eql?, :==

      def hash
        [base_sha, start_sha, head_sha].hash
      end

      # There is only one case in which we will have `start_sha` and `head_sha`,
      # but not `base_sha`, which is when a diff is generated between an
      # orphaned branch and another branch, which means there _is_ no base, but
      # we're still able to highlight it, and to create diff notes, which are
      # the primary things `DiffRefs` are used for.
      # `DiffRefs` are "complete" when they have `start_sha` and `head_sha`,
      # because `base_sha` can always be derived from this, to return an actual
      # sha, or `nil`.
      # We have `base_sha` directly available on `DiffRefs` because it's faster#
      # than having to look it up in the repo every time.
      def complete?
        start_sha && head_sha
      end

      def compare_in(project)
        # We're at the initial commit, so just get that as we can't compare to anything.
        if Gitlab::Git.blank_ref?(start_sha)
          project.commit(head_sha)
        else
          straight = start_sha == base_sha
          CompareService.new(project, head_sha).execute(project, start_sha, straight: straight)
        end
      end

      private

      def shas_equal?(sha1, sha2)
        return true if sha1 == sha2
        return false if sha1.nil? || sha2.nil?
        return false unless sha1.class == sha2.class

        length = [sha1.length, sha2.length].min

        # If either of the shas is below the minimum length, we cannot be sure
        # that they actually refer to the same commit because of hash collision.
        return false if length < Commit::MIN_SHA_LENGTH

        sha1[0, length] == sha2[0, length]
      end
    end
  end
end
