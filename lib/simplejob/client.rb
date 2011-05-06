require "amqp"

module SimpleJob
  DEFAULT_EXCHANGE_NAME = "simplejob"

  class Client
    def self.start(opts = {}, &proc)
      instance = new
      instance.start(opts, &proc)
      instance
    end

    def start(opts, &proc)
      client = self
      AMQP.start(opts) do
        Signal.trap("INT") { puts; stop }
        Signal.trap("TERM") { puts; stop }

        @channel = AMQP::Channel.new
        @exchange = exchange(opts[:exchange_name] || DEFAULT_EXCHANGE_NAME)

        instance_exec(opts, &proc)
      end
    end

    def stop
      AMQP.stop { EM.stop }
    end

    def exchange(name)
      @channel.topic(name, :durable => true, :auto_delete => false)
    end

    def queue(name)
      @channel.queue(name, :durable => true, :auto_delete => false)
    end

    def bind(queue, key)
      queue.bind(@exchange, :key => key)
    end

    def publish(topic, message)
      @exchange.publish(message, :routing_key => topic, :persistent => true)
    end

    def subscribe(queue, &proc)
      queue.subscribe({ :ack => true }, &proc)
    end
  end
end