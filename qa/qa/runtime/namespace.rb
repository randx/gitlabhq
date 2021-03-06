module QA
  module Runtime
    module Namespace
      extend self

      def time
        @time ||= Time.now
      end

      def name
        'qa_test_' + time.strftime('%d_%m_%Y_%H-%M-%S')
      end

      def sandbox_name
        'gitlab-qa-sandbox'
      end
    end
  end
end
