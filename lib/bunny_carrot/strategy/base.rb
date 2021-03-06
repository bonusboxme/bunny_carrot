module BunnyCarrot
  module Strategy
    class Base
      include BunnyCarrot::Logger

      def initialize(args)
        @queue_name       = args.fetch(:queue_name)
        @payload          = args.fetch(:payload)
        @headers          = args.fetch(:message_headers)
        @acknowledge_proc = args.fetch(:acknowledge_proc)
        @exception        = args.fetch(:exception)
        @notify           = args[:notify] || default_notify
        post_initialize(args)
        logger.info "#{self.class.name} initialized"
      end

      def perform
        raise NotImplementedError
      end

      protected

      def post_initialize(args)
      end

      def default_notify
        true
      end

      def drop
        acknowledge
        notify
      end

      def block
        # Doing nothing, blocking queue
        notify
      end

      private

      def acknowledge
        @acknowledge_proc.call
      end

      def publish
        RabbitHole.publish(payload:    @payload,
                           queue_name: @queue_name,
                           headers:    headers)
      end

      def headers
        @headers
      end

      def notify
        if notify?
          logger.info 'Notifying about exception...'
          hash = Hamster.hash(queue_name: @queue_name,
                              exception:  @exception,
                              payload:    @payload)
          BunnyCarrot::ExceptionNotifier.call(hash)
        end
      end

      def notify?
        @notify
      end
    end
  end
end
