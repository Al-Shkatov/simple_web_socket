module EventListener

  def on(event_name, &block)
    @events ||= {}
    @events[event_name.to_s] ||= []

    @events[event_name.to_s] << block
  end

  def trigger(event=nil)
    event_name = event.is_a?(Event) ? event.name : event
    @events[event_name.to_s].each do |block|
      block.call(event)
    end
  # rescue
  #   p 'Event missing '+event_name.to_s
  # ensure
  end
end