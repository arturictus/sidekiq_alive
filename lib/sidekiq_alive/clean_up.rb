module SidekiqAlive
  class CleanUP

    class ScheduledJob
      attr_reader :job, :context
      def initialize(job, context = CleanUP.new)
        @job = job
        @context = context
      end

      def data
        @data ||= JSON.parse(job.first)
      end

      def worker?
        data['class'] == SidekiqAlive::Worker.name
      end

      def current_hostname_worker?
        worker? && data['args'].include?(SidekiqAlive.current_hostname)
      end

      def remove!
        SidekiqAlive.redis.zrem(context.sorted_set, job)
      end
    end

    def sorted_set
      "schedule"
    end


    def remove_all
      clean_own_workers(false)
    end

    def remove_mine
      clean_own_workers(true)
    end

    private

    def clean_own_workers(only_current_hostname = true)
      redis.zrange(sorted_set, 0, -1, :with_scores => true).each do |raw_job|
        job = ScheduledJob.new(raw_job)
        next unless job.worker?
        if only_current_hostname
          if job.current_hostname_worker?
            job.remove!
            break
          end
        else
          job.remove!
        end
      end
    end
  end
end
