require 'rspec/mocks/argument_list_matcher'

module RSpec
  module ActiveJob
    module Matchers
      class EnqueueA
        def initialize(job_class = nil)
          @job_class = job_class
        end

        def matches?(block)
          @before_jobs = enqueued_jobs.dup
          block.call
          enqueued_something? && enqueued_correct_class? && with_correct_args?
        end

        def with(*args)
          raise "Must specify the job class when specifying arguments" unless job_class

          @argument_list_matcher = RSpec::Mocks::ArgumentListMatcher.new(*args)
          self
        end

        def failure_message
          unless enqueued_something?
            return "expected to enqueue a #{job_class || 'job'}, enqueued nothing"
          end

          unless enqueued_correct_class?
            return "expected to enqueue a #{job_class}, " \
                   "enqueued a #{enqueued_jobs.last[:job]}"
          end

          "expected to enqueue a #{job_class} with " \
          "#{argument_list_matcher.expected_args}, but enqueued with " \
          "#{new_jobs_with_correct_class.first[:args]}"
        end

        def supports_block_expectations?
          true
        end

        def description
          return "enqueue a job" unless job_class
          return "enqueue a #{job_class.name}" unless argument_list_matcher
          "enqueue a #{job_class.name} with #{argument_list_matcher.expected_args}"
        end

        private

        attr_reader :before_count, :after_count, :job_class, :argument_list_matcher

        def enqueued_something?
          new_jobs.any?
        end

        def enqueued_correct_class?
          return true unless job_class
          new_jobs_with_correct_class.any?
        end

        def with_correct_args?
          return true unless argument_list_matcher
          new_jobs_with_correct_class_and_args.any?
        end

        def new_jobs
          enqueued_jobs - @before_jobs
        end

        def new_jobs_with_correct_class
          new_jobs.select { |job| job[:job] == job_class }
        end

        def new_jobs_with_correct_class_and_args
          new_jobs_with_correct_class.
            select { |job| argument_list_matcher.args_match?(*job[:args]) }
        end

        def enqueued_jobs
          ::ActiveJob::Base.queue_adapter.enqueued_jobs
        end
      end
    end
  end
end
