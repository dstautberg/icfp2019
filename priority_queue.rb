class PriorityQueue
  def initialize
    @q = []
  end

  def <<(item)
    @q << item
  end

  def pop
    @q.sort!
    @q.pop
  end
end
