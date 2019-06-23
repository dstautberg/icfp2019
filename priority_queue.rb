class PriorityQueue
  def initialize
    @q = []
  end

  def push(priority, item)
    @q << [priority, item]
  end

  def pop
    @q.sort_by! {|item| -item[0]}
    @q.pop[1]
  end
  
  def empty?
    @q.empty?
  end
end
